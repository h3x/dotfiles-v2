#!/usr/bin/env bash
# Rofi script runner with custom order via filename prefixes

source "$HOME/.zshrc"
SCRIPTS_DIR="$HOME/dotfiles/work_scripts/"

# List executable scripts sorted by filename (numbers control order)
SCRIPTS=$(find "$SCRIPTS_DIR" -maxdepth 1 -type f -executable | sort)

echo "Script started" >>/tmp/rofi-work-debug.log
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
FONT = omarchy-font-current
CHOICE=$(echo -e "$MENU" | rofi -dmenu -fuzzy -i -p "Run script:" -font omarchy-font-current)

echo "Choice: $CHOICE" >>/tmp/rofi-work-debug.log
# Exit if no selection
[ -z "$CHOICE" ] && exit 0

# Run the selected script
echo "Running: ${SCRIPT_MAP[$CHOICE]}" >>/tmp/rofi-work-debug.log
${SCRIPT_MAP[$CHOICE]}
