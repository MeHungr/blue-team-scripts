#!/bin/bash

# nft_config.sh - Script to manage nftables installation, configuration, and persistence
# Usage:
#   ./nft_config.sh -i      # Install and enable nftables
#   ./nft_config.sh -a      # Apply default nftables ruleset
#   ./nft_config.sh -s      # Save current ruleset to /etc/nftables.conf
#   ./nft_config.sh -r      # Restore nftables rules from /etc/nftables.backup
#   ./nft_config.sh -f      # Flush current nftables ruleset
#   ./nft_config.sh -ia     # Install and apply rules in one step
#   ./nft_config.sh -rs     # Restore from backup and save it to config for persistence
#   ./nft_config.sh -ifa    # Flush, install, and apply rules in one step

set -e

red='\e[31m'
green='\e[32m'
yellow='\e[33m'
bold='\e[1m'
reset='\e[0m'
# ===== Check for root =====
if [ "$EUID" -ne 0 ]; then
	echo "This script must be run as root. Exiting..."
	exit 1
fi
# Normalize and detect the Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID" | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

# Install nftables based on distro
install_nftables() {
    case "$1" in
        *ubuntu*|*debian*)
            apt-get update
            apt-get install -y nftables
            ;;
        *fedora*)
            dnf install -y nftables
            ;;
        *centos*|*rhel*|*rocky*|*almalinux*)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y nftables
            else
                yum install -y epel-release
                yum install -y nftables
            fi
            ;;
        *arch*)
            pacman -Sy --noconfirm nftables
            ;;
        *suse*|*opensuse*|*sles*)
            zypper install -y nftables
            ;;
        *)
            echo -e "${red}Unsupported distribution: $1${reset}"
            exit 1
            ;;
    esac
}

# Enable and start the nftables service
enable_nftables() {
    systemctl enable --now nftables
}

# Flush current ruleset
flush_ruleset() {
    echo -e "${yellow}Flushing current nftables ruleset...${reset}"
    nft flush ruleset
}

# Apply a default nftables ruleset (with backup if rules exist)
apply_default_ruleset() {
    if nft list ruleset | grep -q 'table'; then
        echo -e "${yellow}Warning: Existing nftables rules detected. Backing them up to /etc/nftables.backup${reset}"
        nft list ruleset > /etc/nftables.backup
    fi

    echo -e "${green}Applying basic default nftables ruleset...${reset}"
    cat <<EOF > /etc/nftables.conf
#!/usr/sbin/nft -f

table inet filter {
    chain input {
        type filter hook input priority 0;
        policy drop;

        ct state established,related accept
        iif "lo" accept
        tcp dport { 22 } accept

        log prefix "nftables-drop-input: " flags all
    }

    chain forward {
        type filter hook forward priority 0;
        policy drop;

        log prefix "nftables-drop-forward: " flags all
    }

    chain output {
        type filter hook output priority 0;
        policy accept;
    }
}
EOF

    systemctl restart nftables
}

# Save current ruleset to config file
save_current_ruleset() {
    echo -e "${green}Saving current ruleset to /etc/nftables.conf...${reset}"
    nft list ruleset > /etc/nftables.conf
}

# Restore rules from backup file
restore_backup_ruleset() {
    if [ -f /etc/nftables.backup ]; then
        echo -e "${yellow}Restoring ruleset from /etc/nftables.backup...${reset}"
        nft flush ruleset
        nft -f /etc/nftables.backup
        echo -e "${green}Restored successfully.${reset}"
    else
        echo -e "${red}No backup file found at /etc/nftables.backup${reset}"
        exit 1
    fi
}

# Display help message
display_help() {
    echo -e "${bold}Usage: $0 [-i] [-a] [-s] [-r] [-f]${reset}"
    echo "  -i    Install and enable nftables"
    echo "  -a    Apply default nftables ruleset"
    echo "  -s    Save current in-memory ruleset to /etc/nftables.conf"
    echo "  -r    Restore nftables ruleset from /etc/nftables.backup"
    echo "  -f    Flush current nftables ruleset"
    echo ""
    echo "Example:"
    echo "  $0 -ia     # Install and apply default ruleset"
    echo "  $0 -rs     # Restore from backup and save it to config for persistence"
    echo "  $0 -f      # Flush current ruleset only"
    echo "  $0 -ifa    # Flush, install, and apply rules in one step"
    exit 1
}

# Parse options with getopts
while getopts "iasrf" opt; do
    case "$opt" in
        i)
            distro=$(detect_distro)
            echo -e "${green}Detected distro: $distro${reset}"
            install_nftables "$distro"
            enable_nftables
            ;;
        a)
            apply_default_ruleset
            ;;
        s)
            save_current_ruleset
            ;;
        r)
            restore_backup_ruleset
            ;;
        f)
            flush_ruleset
            ;;
        *)
            display_help
            ;;
    esac
    found=true

done

# If no flags were provided
if [ -z "$found" ]; then
    display_help
fi

