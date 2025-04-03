#!/bin/bash
# setup/paths.sh

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
ROOT_DIR="$(realpath "$SCRIPT_DIR/..")"

# Load environment config
CONFIG_PATH="$ROOT_DIR/config.env"
source "$CONFIG_PATH"

# Normalize and export all key paths
export ROOT_DIR
export OUTPUT_DIR="$(realpath "$ROOT_DIR/${OUTPUT_DIR:-output}")"
export LOG_DIR="$(realpath "$ROOT_DIR/${LOG_DIR:-$OUTPUT_DIR/logs}")"
export BACKUP_DIR="$(realpath "$ROOT_DIR/${BACKUP_DIR:-$OUTPUT_DIR/backups}")"
export BASELINE_DIR="$(realpath "$ROOT_DIR/${BASELINE_DIR:-$OUTPUT_DIR/baselines}")"
