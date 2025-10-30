
#!/bin/bash
SLACK_CLASS="Slack"
HIDDEN_WS="9"

# Get active monitor dimensions using hyprctl
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

echo "$WIN_WIDTH"
echo "$WIN_HEIGHT"


# Get Slack window ID (address)
WIN_ID=$(hyprctl clients -j | jq -r '.[] | select(.class=="'"$SLACK_CLASS"'") | .address')

if [ -z "$WIN_ID" ]; then
  # Not running, launch Slack
  slack &
  for i in {1..20}; do
    sleep 0.3
    WIN_ID=$(hyprctl clients -j | jq -r '.[] | select(.class=="'"$SLACK_CLASS"'") | .address')
    [ -n "$WIN_ID" ] && break
  done
  hyprctl dispatch setfloating address:$WIN_ID
  hyprctl dispatch resizewindowpixel exact "$WIN_WIDTH" "$WIN_HEIGHT",address:$WIN_ID
  hyprctl dispatch centerwindow address:$WIN_ID
  hyprctl dispatch focuswindow address:$WIN_ID
  exit
fi

# Get current workspace of Slack
SLACK_WS=$(hyprctl clients -j | jq -r '.[] | select(.class=="'"$SLACK_CLASS"'") | .workspace.id')
CUR_WS=$(hyprctl activeworkspace -j | jq -r '.id')

if [ "$SLACK_WS" = "$CUR_WS" ]; then
  # Move to hidden workspace
  hyprctl dispatch movetoworkspacesilent "$HIDDEN_WS,address:$WIN_ID"
  hyprctl dispatch centerwindow address:$WIN_ID
else
  # Move to current workspace and focus
  hyprctl dispatch setfloating address:$WIN_ID
  hyprctl dispatch resizewindowpixel exact "$WIN_WIDTH" "$WIN_HEIGHT",address:$WIN_ID
  hyprctl dispatch centerwindow address:$WIN_ID
  hyprctl dispatch movetoworkspacesilent "$CUR_WS,address:$WIN_ID"
  hyprctl dispatch focuswindow address:$WIN_ID
fi
