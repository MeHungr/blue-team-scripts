#!/bin/bash
#
# check_firewall.sh
# Description: Compares current firewall rules to a baseline set of rules and reports discrepancies

baseline_dir="/var/baselines"  # Directory where baseline firewall rules are stored
temp_file="/tmp/current_nftables_rules.$$"  # Temporary file to store current ruleset
log_file="/tmp/check_firewall.log.$$"  # Temporary log file for script output

# Redirect all script output to the log file
exec > >(tee "$log_file") 2>&1

# ===== ANSI color codes =====
green="\033[0;32m"  # Success messages
yellow="\033[1;33m"  # Warnings
red="\033[0;31m"    # Errors
reset="\033[0m"      # Reset text color

# ===== Check that this is run as root =====
if [ "$EUID" -ne 0 ]; then
  echo -e "${red}[FAIL] This script must be run as root.${reset}"
  exit 1 # Not run as root
fi

# ===== Check for presence of nft command =====
if command -v nft &>/dev/null; then
	baseline_file="$baseline_dir/nftables_rules.baseline"  # Path to nftables baseline file
else
	echo -e "${yellow}[WARN] nft command not found. Firewall check skipped.${reset}"
	exit 2 # nft command not found
fi

# ===== Ensure baseline directory exists =====
if [ ! -d "$baseline_dir" ]; then
    echo -e "${yellow}[WARN] Baseline directory $baseline_dir does not exist. Creating it now...${reset}"
    mkdir -p "$baseline_dir"
    if [ $? -ne 0 ]; then
        echo -e "${red}[FAIL] Could not create baseline directory at $baseline_dir.${reset}"
        exit 4 # Failed to create baseline directory
    fi
fi

# ===== Check if baseline file exists =====
if [ ! -f "$baseline_file" ]; then
	echo -e "${yellow}[WARN] No baseline file found at $baseline_file. Creating one now...${reset}"
    nft list ruleset > "$baseline_file"
    if [ $? -eq 0 ]; then
        echo -e "${green}[OK] Created a baseline file for nftables rules.${reset}"
    else
        echo -e "${red}[FAIL] Could not create baseline file at $baseline_file.${reset}"
        exit 5 # Failed to create baseline file
    fi
fi

# ===== Function: get_ruleset =====
# Retrieves the current nftables ruleset and stores it in a temporary file
get_ruleset () {
	nft list ruleset > "$temp_file" 2>/dev/null
    trap "rm -f \"$temp_file\"" EXIT  # Ensure temp file is deleted on exit
	if [ $? -ne 0 ]; then
		echo -e "${red}[FAIL] Could not retrieve nftables ruleset. Check if nft is running/available.${reset}"
		exit 3 # Could not find ruleset
	fi
}

# ===== Function: compare_ruleset =====
# Compares current ruleset against baseline and reports differences
compare_ruleset () {
	diff -u "$baseline_file" "$temp_file" > /dev/null 2>&1
    # If diff returns a difference in the files:
	if [ $? -ne 0 ]; then
		echo -e "${red}[FAIL] The nftables ruleset differs from baseline.${reset}"
        diff -u "$baseline_file" "$temp_file"  # Show the differences

        # Restore to the baseline file
        nft -f "$baseline_file"
        if [ $? -eq 0 ]; then
            nft list ruleset > /etc/nftables.conf
            systemctl restart nftables
	    systemctl enable nftables
            echo -e "${green}[OK] Baseline firewall ruleset restored.${reset}"
            echo "[FIREWALL-RESTORE] $(date): Baseline nftables ruleset restored due to mismatch"
            exit 10  # Distinct exit code for restore event
        else
            echo -e "${red}[FAIL] Failed to restore baseline ruleset.${reset}"
            echo "[FIREWALL-RESTORE-FAIL] $(date): Attempted to restore baseline nftables ruleset but failed"
            exit 11 # Exit code for restore fail event
        fi
	else
		echo -e "${green}[OK] firewall ruleset matches baseline.${reset}"
        exit 0
	fi
}

# ===== Main Execution =====
echo "$log_file" # Echoes the location of the log file at the top for use in the main script
get_ruleset
compare_ruleset

