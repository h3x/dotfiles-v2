#!/bin/bash
if [ -z "$1" ]; then
  echo "Usage: $0 <WindowClass>"
  exit 1
fi

HIDDEN_WS="9"
WIN_CLASS="$1"

# Get window ID (address)
WIN_ID=$(hyprctl clients -j | jq -r '.[] | select(.class=="'"$WIN_CLASS"'") | .address')

if [ -z "$WIN_ID" ]; then
  # Not running, launch app and wait for it to appear
  "$WIN_CLASS" &
  sleep 0.7
  WIN_ID=$(hyprctl clients -j | jq -r '.[] | select(.class=="'"$WIN_CLASS"'") | .address')
  if [ -z "$WIN_ID" ]; then
    echo "Failed to find window for class $WIN_CLASS"
    exit 1
  fi
  hyprctl dispatch setfloating address:$WIN_ID
  hyprctl dispatch resizewindowpixel exact 1200 800,address:$WIN_ID
  hyprctl dispatch centerwindow address:$WIN_ID
  hyprctl dispatch focuswindow address:$WIN_ID
  exit
fi

# Get current workspace of window
WIN_WS=$(hyprctl clients -j | jq -r '.[] | select(.class=="'"$WIN_CLASS"'") | .workspace.id')
CUR_WS=$(hyprctl activeworkspace -j | jq -r '.id')

if [ "$WIN_WS" = "$CUR_WS" ]; then
  # Move to hidden workspace
  hyprctl dispatch movetoworkspacesilent "$HIDDEN_WS,address:$WIN_ID"
else
  # Move to current workspace, float, resize, center, and focus
  hyprctl dispatch setfloating address:$WIN_ID
  hyprctl dispatch resizewindowpixel exact 1200 800,address:$WIN_ID
  hyprctl dispatch centerwindow address:$WIN_ID
  hyprctl dispatch movetoworkspacesilent "$CUR_WS,address:$WIN_ID"
  hyprctl dispatch focuswindow address:$WIN_ID
fi
