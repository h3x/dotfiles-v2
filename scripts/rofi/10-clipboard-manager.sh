#!/usr/bin/env bash
# Rofi clipboard manager - last 10 entries, numbered selection, multiline-safe
# 0 = Clear clipboard

HISTORY_FILE="$HOME/.local/share/rofi_clipboard_history"
MAX_ENTRIES=10
MENU_LINE_LENGTH=50
NEWLINE_PLACEHOLDER="↵"

# Ensure history file exists
mkdir -p "$(dirname "$HISTORY_FILE")"
touch "$HISTORY_FILE"

# Get current clipboard
CURRENT=$(wl-paste -n 2>/dev/null)

# Encode newlines for storage
if [ -n "$CURRENT" ]; then
    ENCODED=$(echo -n "$CURRENT" | sed ':a;N;$!ba;s/\n/\\n/g')
    # Remove duplicate if exists
    grep -Fxv "$ENCODED" "$HISTORY_FILE" > "$HISTORY_FILE.tmp" 2>/dev/null
    echo "$ENCODED" >> "$HISTORY_FILE.tmp"
    mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
fi

# Keep only last MAX_ENTRIES
tail -n $MAX_ENTRIES "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"

# Build menu: start with 0 = clear
MENU="0. Clear Clipboard\n"
i=1
while read -r line; do
    # Replace stored newline markers with placeholder for display
    DISPLAY_LINE=$(echo "$line" | sed 's/\\n/'"$NEWLINE_PLACEHOLDER"'/g' | cut -c1-$MENU_LINE_LENGTH)
    MENU+="$i. $DISPLAY_LINE\n"
    i=$((i+1))
done < <(tac "$HISTORY_FILE")  # most recent first

# Show Rofi menu
CHOICE=$(echo -e "$MENU" | rofi -dmenu -p "Clipboard (0-$MAX_ENTRIES):" -lines $((MAX_ENTRIES+1)))
[ -z "$CHOICE" ] && exit 0

# Extract number
NUM=$(echo "$CHOICE" | awk -F. '{print $1}')

if [ "$NUM" = "0" ]; then
    echo -n | wl-copy
    > "$HISTORY_FILE"
    notify-send "📋 Clipboard Cleared"
    exit 0
fi

# Get selected snippet
SELECTED=$(tac "$HISTORY_FILE" | sed -n "${NUM}p" | sed 's/\\n/\n/g')

# Copy full text back to clipboard
echo -n "$SELECTED" | wl-copy

# Notify user
notify-send "📋 Clipboard Selected" "$(echo "$SELECTED" | head -c 100 | tr '\n' ' ')"
