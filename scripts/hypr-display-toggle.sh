#!/usr/bin/env bash
# Auto-toggle between laptop and external displays for Hyprland.
# Special case: set fixed resolution for a specific ultrawide monitor.

INTERNAL="eDP-1"
MONS=$(hyprctl monitors all)
EXTERNAL=$(echo "$MONS" | grep "Monitor " | grep -v "$INTERNAL" | awk '{print $2}' | head -n 1)

# Give Hyprland a moment to detect changes
sleep 1
echo "$EXTERNAL"

if [ -n "$EXTERNAL" ]; then
#     # Check the monitor description (model/serial)
    DESC=$(hyprctl monitors all | awk "/Monitor $EXTERNAL/,/current mode/" | grep description: | awk '{print $6}')
    if [ "$DESC" = "112NTWGFV697" ]; then
        echo "Matched special monitor ($DESC) — forcing 2560x1080@60."
        hyprctl keyword monitor HDMI-A-2,2560x1080@60,auto,1
        hyprctl keyword monitor "$INTERNAL,disable"
    else
        RESMODE=$(echo "$MONS" | awk "/Monitor $EXTERNAL/,/current mode/" | grep "current mode" | awk '{print $3}')
        [ -z "$RESMODE" ] && RESMODE="preferred"
        echo "External $EXTERNAL ($DESC) detected with mode $RESMODE."
        hyprctl keyword monitor "$INTERNAL,disable"
        hyprctl keyword monitor "$EXTERNAL,${RESMODE%%@*}@${RESMODE##*@},auto,1"
    fi
else
    echo "No external monitor detected — enabling laptop display only."
    hyprctl keyword monitor "$INTERNAL,preferred,0x0,1"
    for m in $(echo "$MONS" | grep "Monitor " | grep -v "$INTERNAL" | awk '{print $2}'); do
        hyprctl keyword monitor "$m,disable"
    done
fi
