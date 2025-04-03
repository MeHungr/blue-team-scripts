check_firewall=OK
check_services=OK

service_log_path="/var/log/service_check.log"

# Run checks here
firewall_output="$(./check_firewall.sh)"
firewall_log_path="$(echo -e "$firewall_output" | head -n 1)"
firewall_exit=$?

# Log everything except the log path line
echo "$firewall_output" | head -n -1 >> "$service_log_path"
echo "[LOG] Full firewall check log stored at $firewall_log_path" >> "$service_log_path"

# Discord logging !!
./discord_send.sh "$(cat $service_log_path)"
