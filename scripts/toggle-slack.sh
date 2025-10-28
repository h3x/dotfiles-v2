
#!/bin/bash
SLACK_CLASS="Slack"
HIDDEN_WS="9"

# Get Slack window ID (address)
WIN_ID=$(hyprctl clients -j | jq -r '.[] | select(.class=="'"$SLACK_CLASS"'") | .address')

if [ -z "$WIN_ID" ]; then
  # Not running, launch Slack
  slack &
  exit
fi

# Get current workspace of Slack
SLACK_WS=$(hyprctl clients -j | jq -r '.[] | select(.class=="'"$SLACK_CLASS"'") | .workspace.id')
CUR_WS=$(hyprctl activeworkspace -j | jq -r '.id')

if [ "$SLACK_WS" = "$CUR_WS" ]; then
  # Move to hidden workspace
  hyprctl dispatch movetoworkspacesilent "$HIDDEN_WS,address:$WIN_ID"
else
  # Move to current workspace and focus
  hyprctl dispatch movetoworkspacesilent "$CUR_WS,address:$WIN_ID"
  hyprctl dispatch focuswindow address:$WIN_ID
fi
