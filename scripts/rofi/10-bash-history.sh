#!/usr/bin/env bash

HISTORY_FILE="$HOME/.zsh_history"

HISTORY=$(awk -F';' '{print $NF}' "$HISTORY_FILE" | tac | awk '!seen[$0]++')

CHOICE=$(echo "$HISTORY" | rofi -dmenu -p "Bash history:" -lines 20 -fuzzy -i)

[ -z "$CHOICE" ] && exit 0

# Copy selected command to clipboard
echo -n "$CHOICE" | wl-copy

# Notify user
notify-send "📋 Bash Command Copied" "$CHOICE"
