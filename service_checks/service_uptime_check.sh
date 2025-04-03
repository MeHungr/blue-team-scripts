#!/bin/bash

# The full uptime log (persistent)
full_log="/var/log/service_check_full.log"
# The single-run log (overwritten each run)
run_log="/var/log/service_check.log"

# Clear the single run log
> "$run_log"

# ===== Run Firewall Check =====
firewall_output="$(./check_firewall.sh)"
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
./discord_send.sh "$(cat $service_log_path)"

# ===== Show user where the log file is =====
echo "Done! The logs can be viewed at: $full_log"
