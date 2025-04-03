#!/bin/bash

# ===== Dependency Check =====
ensure_jq_installed() {
    if command -v jq &>/dev/null; then return 0; fi

    echo "[info] 'jq' not found. Attempting to install..."

    if command -v apt &>/dev/null; then
        sudo apt update && sudo apt install -y jq && return 0
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y jq && return 0
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy jq --noconfirm && return 0
    elif command -v yum &>/dev/null; then
        sudo yum install -y jq && return 0
    fi

    echo "[error] Could not install jq. Please install it manually."
    exit 1
}

ensure_jq_installed

# ===== Input Handling =====
message="$1"
discord_webhook_url="$2"
max_chars=1900  # Slightly under Discord's 2000-char limit

# ===== Usage Help =====
if [[ -z "$message" || -z "$discord_webhook_url" ]]; then
    echo "Usage: $0 <message> <discord_webhook_url>"
    echo "Example:"
    echo "  $0 \"The system check failed!\" https://discord.com/api/webhooks/..."
    exit 1
fi

# ===== Function: Send one chunk =====
send_chunk() {
    local chunk="$1"
    curl -s -X POST "$discord_webhook_url" \
        -H "Content-Type: application/json" \
        -d "$(jq -n --arg content "$chunk" '{content: $content}')" >/dev/null

    if [[ $? -ne 0 ]]; then
        echo "[error] Failed to send message chunk to Discord."
        exit 2
    fi
}

# ===== Split and send message =====
while IFS= read -r -n "$max_chars" chunk || [[ -n "$chunk" ]]; do
    send_chunk "$chunk"
done < <(printf "%s" "$message")
