#!/usr/bin/env bash
# Rofi script runner with custom order via filename prefixes

SCRIPTS_DIR="$HOME/dotfiles/scripts/rofi"

# List executable scripts sorted by filename (numbers control order)
SCRIPTS=$(find "$SCRIPTS_DIR" -maxdepth 1 -type f -executable | sort)

# Build menu with prettified names
MENU=""
declare -A SCRIPT_MAP

for script in $SCRIPTS; do
    # Get basename
    NAME=$(basename "$script")
    # Remove .sh extension
    NAME="${NAME%.sh}"
    # Remove leading numbers and optional dash (e.g., 10-)
    NAME="${NAME#[0-9]*-}"
    # Replace dashes with spaces
    NAME="${NAME//-/ }"
    # Capitalize each word
    NAME=$(echo "$NAME" | awk '{for(i=1;i<=NF;i++){ $i=toupper(substr($i,1,1)) substr($i,2) } print}')
    # Add to menu and map back to full path
    MENU+="$NAME\n"
    SCRIPT_MAP["$NAME"]="$script"
done

# Show Rofi menu
CHOICE=$(echo -e "$MENU" | rofi -dmenu -p "Run script:")

# Exit if no selection
[ -z "$CHOICE" ] && exit 0

# Run the selected script
"${SCRIPT_MAP[$CHOICE]}"
