#!/bin/bash

service_log_path="/var/log/service_check.log"
> "$service_log_path" # Empty the log
# Run checks here
firewall_output="$(./check_firewall.sh)"
firewall_log_path="$(echo "$firewall_output" | head -n 1)"
firewall_exit=$?

# Log everything except the log path line
echo "$firewall_output" | tail -n +2 >> "$service_log_path"
echo "[LOG] Full firewall check log stored at $firewall_log_path" >> "$service_log_path"

# Discord logging !!
./discord_send.sh "$(cat $service_log_path)"

