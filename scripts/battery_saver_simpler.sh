#!/bin/bash

THRESHOLD=30

while true; do
    battery_info=$(upower -i $(upower -e | grep BAT) 2>/dev/null)
    battery_level=$(echo "$battery_info" | awk '/percentage/ {print $2}' | tr -d '%')
    battery_state=$(echo "$battery_info" | awk '/state/ {print $2}')

    # Default to 100 if upower fails
    battery_level=${battery_level:-100}

    if [[ "$battery_state" == "discharging" ]] && [[ "$battery_level" -le $THRESHOLD ]]; then
        notify-send -u critical "⚡ Battery Low!" "Battery at ${battery_level}% - Connect charger!"
        paplay /usr/share/sounds/freedesktop/stereo/dialog-warning.oga
    fi

    sleep 300
done
