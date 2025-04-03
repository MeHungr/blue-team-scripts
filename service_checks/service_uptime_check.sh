#!/bin/bash

# ===== Source config.env and set up paths =====
source "$(dirname "$(realpath "$0")")/../setup/paths.sh"

# ===== ANSI color codes =====
green="\033[0;32m"
yellow="\033[1;33m"
red="\033[0;31m"
reset="\033[0m"

# ===== Parse Mode =====
MODE="${1:-check}"

case "$MODE" in
    check|baseline)
        echo "[INFO] Running in $MODE mode"
        ;;
    help|--help|-h)
        echo "Usage: $0 [check|baseline]"
        echo "  check     - run service and system checks (default)"
        echo "  baseline  - create or update baseline files"
        exit 0
        ;;
    *)
        echo "[ERROR] Unknown mode: $MODE"
        echo "Run '$0 help' for usage."
        exit 1
        ;;
esac

# ===== Log Files =====
full_log="$LOG_DIR/service_check_full.log"
run_log="$LOG_DIR/service_check.log"

# Clear the single run log
> "$run_log"

# ===== Function: run_check =====
# Runs a check script with given mode and optionally
# sends output to discord.
run_check() {
    local script_path="$1"
    local label
    label="$(basename "$script_path" .sh)"  # check_firewall
    local temp_log="/tmp/${label}_check.log"

    echo "[RUNNING] $label" | tee -a "$run_log"

    # Run check and capture logs
    "$script_path" "$mode" | tee >(tee -a "$full_log") >> "$temp_log"
    cat "$temp_log" >> "$run_log"

    echo "[DONE] $label" | tee -a "$run_log"
    echo >> "$run_log"

    # ===== Discord Output =====
    if [ "$discord" = true ]; then
        # Extract the check name and convert to uppercase
        local base="${label#check_}"                # check_firewall → firewall
        local var_name="${base^^}_WEBHOOK_URL"      # firewall → FIREWALL_WEBHOOK_URL
        local webhook="${!var_name}"                # Indirect expansion

        if [[ -n "$webhook" ]]; then
            ./discord_send.sh "$(cat "$temp_log")" "$webhook"
        else
            echo "[WARN] No webhook configured for $base ($var_name not set)" | tee -a "$run_log"
        fi
    fi
}

# ===== Function: show_log_summary =====
show_log_summary() {
    (cat "$run_log"; echo -e "${green}Done! The full log can be viewed at: ${yellow}$full_log${reset}") | less -R
}

# Clear the single-run log
> "$run_log"

# ===== Log Header =====
{
    echo "==================== SERVICE UPTIME CHECK ===================="
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Hostname: $(hostname)"
    echo "Mode: $MODE"
    echo "============================================================="
    echo
} >> "$run_log"

# ===== Run All Checks =====
run_check "$ROOT_DIR/service_checks/check_firewall.sh"
run_check "$ROOT_DIR/service_checks/check_services.sh"

# ===== Discord Alert =====
if [ "$DISCORD" = true ]; then
    ./discord_send.sh "$(cat "$run_log")" "$LOGGING_WEBHOOK_URL"
fi

# ===== Show Output =====
show_log_summary

