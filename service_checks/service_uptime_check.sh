#!/bin/bash

# ===== Source config.env =====
# Also initializes output directories and configures paths
source "$(dirname "$(realpath "$0")")/../setup/paths.sh"

# ===== ANSI color codes =====
green="\033[0;32m"  # Success messages
yellow="\033[1;33m"  # Warnings
red="\033[0;31m"    # Errors
reset="\033[0m"      # Reset text color

# The full uptime log (persistent)
full_log="$LOG_DIR/service_check_full.log"
# The single-run log (overwritten each run)
run_log="$LOG_DIR/service_check.log"

# Clear the single run log
> "$run_log"

# ===== Run Firewall Check =====
firewall_output="$("$ROOT_DIR/service_checks/check_firewall.sh")"
firewall_exit=$?
firewall_log_path="$(echo "$firewall_output" | head -n 1)"

# === Append the firewall logs if not empty ===
if [[ -n "$firewall_log_path" && "$firewall_log_path" == /* && -f "$firewall_log_path" && -s "$firewall_log_path" ]]; then
	echo "$firewall_output" | tail -n +2 >> "$run_log"
	echo "[LOG] Full firewall check log stored at $firewall_log_path" >> "$run_log"
else
	echo "$firewall_output" | tail -n +2 >> "$run_log"
	echo "[LOG] Firewall check did not return a valid log path or the file is empty." >> "$run_log"
fi
# ===== Append this run's log to the full uptime log =====
cat "$run_log" >> "$full_log"

# ===== Send this run's log to discord =====
if [ "$DISCORD" = true ]; then
	./discord_send.sh "$(cat $run_log)"
fi
# ===== Show user output in less =====
(cat "$run_log"; echo -e "${green}Done! The full log can be viewed at: ${yellow}$full_log${reset}") | less -R

