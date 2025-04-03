#!/bin/bash
# Ensure all output directories exist

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/paths.sh"

mkdir -p "$LOG_DIR" "$BACKUP_DIR" "$BASELINE_DIR"

echo "[INIT] Output directories ready:"
echo "  Logs:      $LOG_DIR"
echo "  Backups:   $BACKUP_DIR"
echo "  Baselines: $BASELINE_DIR"
