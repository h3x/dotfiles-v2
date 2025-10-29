#!/usr/bin/env bash
# Interactive Hyprland display selector using rofi.
# - Lists monitors
# - Lets you pick a resolution
# - Marks the current mode with *
# - Sets scale=1.6 when applying
# - Offers quick actions for enabling/disabling displays

set -euo pipefail

SCALE="1.6"
INTERNAL="eDP-1"

# --- fetch monitor info ---
MON_INFO="$(hyprctl monitors all)"
MON_LIST=$(printf "%s\n" "$MON_INFO" | grep '^Monitor ' | awk '{print $2}')

# --- add quick actions ---
MON_MENU=$(printf "%s\n[disable monitor]\n[enable laptop]" "$MON_LIST")

# --- pick monitor ---
SELECTED_MON=$(echo "$MON_MENU" | rofi -dmenu -p "Select monitor:")
[ -z "$SELECTED_MON" ] && exit 0

# --- quick action: disable ---
if [ "$SELECTED_MON" = "[disable monitor]" ]; then
    ACTIVE_MONITORS=$(hyprctl monitors all | grep '^Monitor ' | awk '{print $2}')
    ACTIVE_COUNT=$(echo "$ACTIVE_MONITORS" | wc -l)

    if [ "$ACTIVE_COUNT" -le 1 ]; then
        notify-send "Display" "Refusing to disable the only active monitor."
        exit 0
    fi

    TARGET=$(echo "$ACTIVE_MONITORS" | rofi -dmenu -p "Disable which monitor:")
    [ -z "$TARGET" ] && exit 0

    # Double-check we’re not disabling the last one (e.g., race condition)
    if [ "$(echo "$ACTIVE_MONITORS" | grep -v "$TARGET" | wc -l)" -eq 0 ]; then
        notify-send "Display" "Cannot disable all monitors — one must remain active."
        exit 0
    fi

    hyprctl keyword monitor "$TARGET,disable"
    notify-send "Display" "Disabled $TARGET"
    exit 0
fi

# --- quick action: enable laptop ---
if [ "$SELECTED_MON" = "[enable laptop]" ]; then
    hyprctl keyword monitor "$INTERNAL,preferred,0x0,$SCALE"
    for m in $MON_LIST; do
        [ "$m" != "$INTERNAL" ] && hyprctl keyword monitor "$m,disable"
    done
    notify-send "Display" "Enabled laptop display ($INTERNAL)"
    exit 0
fi

# --- extract monitor block ---
MON_BLOCK=$(printf "%s\n" "$MON_INFO" | awk "/^Monitor $SELECTED_MON/ {p=1; next} /^Monitor / && p{exit} p{print}")

if [ -z "$MON_BLOCK" ]; then
    notify-send "Display" "Could not find info for $SELECTED_MON"
    exit 1
fi

# --- get current mode ---
CURRENT_RAW=$(printf "%s\n" "$MON_BLOCK" | sed -n '/\S/ {p;q}' | awk '{print $1}')
CURRENT_MODE=$(echo "$CURRENT_RAW" | sed -E 's/@([0-9]+)\..*/@\1/' | sed 's/Hz//')

# --- get available modes ---
AV_LINE=$(printf "%s\n" "$MON_BLOCK" | awk -F': ' '/availableModes/ {print $2}')
if [ -z "$AV_LINE" ]; then
    notify-send "Display" "No available modes for $SELECTED_MON"
    exit 1
fi

# --- normalize modes list ---
MODE_LINES=$(printf "%s\n" $AV_LINE | sed 's/Hz//g' | awk '
{
  if (match($0, /@/)) {
    split($0,a,"@")
    freq=a[2]
    sub(/\..*/,"",freq)
    printf "%s@%s\n", a[1], freq
  } else {
    print $0
  }
}' | awk '!seen[$0]++')

# --- build list for rofi ---
ROFI_MODES=""
while IFS= read -r m; do
    if [ "$m" = "$CURRENT_MODE" ]; then
        ROFI_MODES+="* $m\n"
    else
        ROFI_MODES+="$m\n"
    fi
done <<< "$MODE_LINES"

SELECTED_MODE=$(echo -e "$ROFI_MODES" | rofi -dmenu -p "Select resolution:" | sed 's/^\* //')
[ -z "$SELECTED_MODE" ] && exit 0

# --- confirm action ---
ACTION=$(echo -e "Apply\nApply and disable others\nCancel" | rofi -dmenu -p "Action for $SELECTED_MON ($SELECTED_MODE @ $SCALE):")
[ -z "$ACTION" ] && exit 0
[ "$ACTION" = "Cancel" ] && exit 0

# --- apply ---
notify-send "Display" "Setting $SELECTED_MON → $SELECTED_MODE @ scale $SCALE"
hyprctl keyword monitor "$SELECTED_MON,$SELECTED_MODE,auto,$SCALE"

if [ "$ACTION" = "Apply and disable others" ]; then
    for m in $MON_LIST; do
        [ "$m" != "$SELECTED_MON" ] && hyprctl keyword monitor "$m,disable"
    done
fi

notify-send "Display" "$SELECTED_MON set to $SELECTED_MODE @ $SCALE"
