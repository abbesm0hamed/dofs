#!/bin/bash

# Default location (latitude and longitude)
LATITUDE="36.8"
LONGITUDE="10.2"

# Validate latitude and longitude values
validate_coordinates() {
    if ! [[ "$LATITUDE" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || ! [[ "$LONGITUDE" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo "Invalid latitude or longitude values. Using defaults."
        LATITUDE="36.8"
        LONGITUDE="10.2"
    fi
}

# Function to check if gammastep is running
is_running() {
    pgrep -x gammastep >/dev/null
}

# Function to toggle gammastep
toggle() {
    if is_running; then
        pkill gammastep
        gammastep -x
    else
        validate_coordinates
        gammastep -l "$LATITUDE:$LONGITUDE" -t 6500:2700 -P &
    fi
}

# Handle command line argument
if [[ "$1" == "toggle" ]]; then
    toggle
    exit 0
fi

# Output status with meaningful icons
if is_running; then
    echo "󰖔" # Crescent moon (night light active)
else
    echo "󰖙" # Sun with face (night light inactive)
fi
