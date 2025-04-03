#!/bin/bash

# The raw message to send
message="$@"
clean_message=$(echo "$message" | sed 's/\x1b\[[0-9;]*m//g')
url="https://discord.com/api/webhooks/1356845689371623434/5-jVkL9zKPcZjvFwEJT-raRMrRulaLiY5Rk6UntH78WvcW1EmA2APwkbLJsN51ipEePy"

payload=$(jq -n --arg content "$clean_message" '{content: $content}')

curl -H "Content-Type: application/json" \
	-X POST \
	-d "$payload" \
	"$url"
