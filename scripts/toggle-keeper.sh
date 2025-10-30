
#!/bin/bash

HIDDEN_WS="9"
WIN_CLASS="Keeper Password Manager"

# Get window ID (address)
WIN_ID=$(hyprctl clients -j | jq -r '.[] | select(.class=="'"$WIN_CLASS"'") | .address')

read SCREEN_WIDTH SCREEN_HEIGHT < <(
  hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.width) \(.height)"'
)

# Calculate window size
if [ "$SCREEN_WIDTH" -gt 1920 ]; then
  WIN_WIDTH=$((SCREEN_WIDTH * 60 / 100))
else
  WIN_WIDTH=$((SCREEN_WIDTH * 85 / 100))
fi
WIN_HEIGHT=$((SCREEN_HEIGHT * 80 / 100))


if [ -z "$WIN_ID" ]; then
  # Not running, launch app and wait for it to appear
  keeperpasswordmanager --new-window &
  WIN_ID=$(hyprctl clients -j | jq -r '.[] | select(.class=="'"$WIN_CLASS"'") | .address')
  for i in {1..20}; do
    sleep 0.3
    WIN_ID=$(hyprctl clients -j | jq -r '.[] | select(.class=="'"$WIN_CLASS"'") | .address')
    [ -n "$WIN_ID" ] && break
  done
  hyprctl dispatch setfloating address:$WIN_ID
  hyprctl dispatch resizewindowpixel exact "$WIN_WIDTH" "$WIN_HEIGHT",address:$WIN_ID
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
  hyprctl dispatch resizewindowpixel exact "$WIN_WIDTH" "$WIN_HEIGHT",address:$WIN_ID
  hyprctl dispatch centerwindow address:$WIN_ID
else
  # Move to current workspace, float, resize, center, and focus
  hyprctl dispatch setfloating address:$WIN_ID
  hyprctl dispatch resizewindowpixel exact "$WIN_WIDTH" "$WIN_HEIGHT",address:$WIN_ID
  hyprctl dispatch centerwindow address:$WIN_ID
  hyprctl dispatch movetoworkspacesilent "$CUR_WS,address:$WIN_ID"
  hyprctl dispatch focuswindow address:$WIN_ID
fi


