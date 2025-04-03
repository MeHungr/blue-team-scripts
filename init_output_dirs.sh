#!/bin/bash
# init_output_dirs.sh - Ensures all output directories exist

# Get root directory (assumes this script is in the same folder as service_uptime_check.sh)
script_dir="$(dirname "$(realpath "$0")")"

# Load environment config
source "$script_dir/config.env"

# Default to prevent unbound variable errors if any path is missing
: "${OUTPUT_DIR:=$script_dir/output}"
: "${LOG_DIR:=$OUTPUT_DIR/logs}"
: "${BACKUP_DIR:=$OUTPUT_DIR/backups}"
: "${BASELINE_DIR:=$OUTPUT_DIR/baselines}"

# Create directories if they don't exist
mkdir -p "$LOG_DIR" "$BACKUP_DIR" "$BASELINE_DIR"

echo "[INIT] Output directories ensured:"
echo "  Logs:      $LOG_DIR"
echo "  Backups:   $BACKUP_DIR"
echo "  Baselines: $BASELINE_DIR"

