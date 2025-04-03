#!/bin/bash

# ===== Source config.env =====
# Also initializes output directories and configures paths
source "$(dirname "$(realpath "$0")")/../setup/paths.sh"

# ===== ANSI color codes =====
green="\033[0;32m"   # Success messages
yellow="\033[1;33m"  # Warnings
red="\033[0;31m"     # Errors
reset="\033[0m"      # Reset text color

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

# ===== Run Checks with Logging =====
"$ROOT_DIR/service_checks/check_firewall.sh" "$MODE" \
    | tee >(tee -a "$full_log") >> "$run_log"


# ===== Send log to Discord if enabled =====
if [ "$DISCORD" = true ]; then
    ./discord_send.sh "$(cat "$run_log")"
fi

# ===== Show user output =====
(cat "$run_log"; echo -e "${green}Done! The full log can be viewed at: ${yellow}$full_log${reset}") | less -R

