#!/usr/bin/env bash
# Rofi Kill Menu (user-owned processes only)

# List only processes owned by your user
PROCS=$(ps -u $(whoami) -o pid=,comm= | awk '{printf "%s - %s\n",$1,$2}')

MENU="0 - Cancel\n$PROCS"

CHOICE=$(echo -e "$MENU" | rofi -dmenu -p "Kill process:" -lines 20)
[ -z "$CHOICE" ] && exit 0

PID=$(echo "$CHOICE" | awk -F' - ' '{print $1}')
[ "$PID" = "0" ] && exit 0

kill "$PID" 2>/dev/null || kill -9 "$PID" 2>/dev/null

PROCESS_NAME=$(echo "$CHOICE" | awk -F' - ' '{print $2}')
notify-send "🛑 Process killed" "$PROCESS_NAME ($PID)"
