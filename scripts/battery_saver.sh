#!/bin/bash

# Simplified configuration
THRESHOLD=20
LOW_BRIGHTNESS=10
BRIGHTNESS_STORE="/tmp/original_brightness"
NOTIFIED_FLAG="/tmp/low_battery_notified"

# Cleanup temporary files on exit
cleanup() { rm -f "$BRIGHTNESS_STORE" "$NOTIFIED_FLAG"; }
trap cleanup EXIT

# Get initial max brightness once
MAX_BRIGHTNESS=$(brightnessctl max)
TARGET_BRIGHTNESS=$((MAX_BRIGHTNESS * LOW_BRIGHTNESS / 100))

# Unified power status check function
get_power_status() {
    local battery_info=$(upower -i $(upower -e | grep 'BAT') 2>/dev/null)
    echo "$battery_info" | awk '/percentage/ {print $2}' | tr -d '%'
    echo "$battery_info" | awk '/state/ {print $2}'
}

# Main monitoring loop
while true; do
    # Read battery status using upower
    read -r BATTERY_LEVEL BATTERY_STATE < <(get_power_status)

    # Default to 100% if upower fails
    BATTERY_LEVEL=${BATTERY_LEVEL:-100}

    # Current brightness value
    CURRENT_BRIGHTNESS=$(brightnessctl get)

    # --- Low Battery Handling ---
    if [[ "$BATTERY_STATE" == "discharging" ]] &&
        [[ "$BATTERY_LEVEL" -le "$THRESHOLD" ]]; then

        # Store original brightness if not saved
        if [[ ! -f "$BRIGHTNESS_STORE" ]]; then
            echo "$CURRENT_BRIGHTNESS" >"$BRIGHTNESS_STORE"
            brightnessctl set "$TARGET_BRIGHTNESS" >/dev/null
        fi

        # Single notification per low-battery event
        if [[ ! -f "$NOTIFIED_FLAG" ]]; then
            notify-send -u critical "Battery Low" \
                "Battery at ${BATTERY_LEVEL}%. Brightness reduced." \
                -a "System"
            touch "$NOTIFIED_FLAG"
        fi

    # --- AC Power Restored ---
    elif [[ "$BATTERY_STATE" == "charging" ]] ||
        [[ "$BATTERY_STATE" == "fully-charged" ]]; then
        if [[ -f "$BRIGHTNESS_STORE" ]]; then
            brightnessctl set "$(cat "$BRIGHTNESS_STORE")" >/dev/null
            rm -f "$BRIGHTNESS_STORE" "$NOTIFIED_FLAG"
            notify-send "Power Connected" "Brightness restored." -a "System"
        fi
    fi

    # Efficient polling interval
    sleep 300
done
