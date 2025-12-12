#!/bin/bash

MAX_RETRIES=3
RETRY_DELAY=2
# Check if required commands are available
if ! command -v curl >/dev/null 2>&1; then
    echo "curl not found"
    exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found"
    exit 1
fi
# Function to fetch location with retries
fetch_location() {
    for ((i = 1; i <= MAX_RETRIES; i++)); do
        LOCATION=$(curl -s http://ip-api.com/json | jq -r '.lat,.lon' | paste -sd, -)
        if [ ! -z "$LOCATION" ] && [ "$LOCATION" != "null" ]; then
            return 0
        fi
        if [ $i -lt $MAX_RETRIES ]; then
            sleep $RETRY_DELAY
        fi
    done
    return 1
}
# Function to fetch prayer data with retries
fetch_prayer_data() {
    local latitude=$1
    local longitude=$2
    for ((i = 1; i <= MAX_RETRIES; i++)); do
        prayer_data=$(curl -s "http://api.aladhan.com/v1/calendar/$(date +%Y)/$(date +%m)?latitude=$latitude&longitude=$longitude&method=3")
        if [ ! -z "$prayer_data" ] && echo "$prayer_data" | jq -e '.data' >/dev/null; then
            return 0
        fi
        if [ $i -lt $MAX_RETRIES ]; then
            sleep $RETRY_DELAY
        fi
    done
    return 1
}
# Try to fetch location
if ! fetch_location; then
    echo "Location unavailable"
    exit 1
fi
# Extract latitude and longitude
latitude=$(echo "$LOCATION" | cut -d',' -f1)
longitude=$(echo "$LOCATION" | cut -d',' -f2)
# Prayer names in order
declare -a prayer_names=("Fajr" "Dhuhr" "Asr" "Maghrib" "Isha")
# Get current time in 24-hour format
current_time=$(date +%H:%M)
# Try to fetch prayer data
if ! fetch_prayer_data "$latitude" "$longitude"; then
    echo "Prayer data unavailable"
    exit 1
fi
# Extract today's prayer times - FIX: Remove leading zeros from day
today=$(date +%d)
today=$((10#$today)) # Force decimal interpretation, removing leading zeros
prayer_times=()
for prayer in "Fajr" "Dhuhr" "Asr" "Maghrib" "Isha"; do
    time=$(echo "$prayer_data" | jq -r ".data[$((today - 1))].timings.$prayer" | cut -d' ' -f1)
    prayer_times+=("$time")
done
# Find next prayer
next_prayer=""
next_prayer_name=""
for i in "${!prayer_times[@]}"; do
    if [[ "${prayer_times[i]}" > "$current_time" ]]; then
        next_prayer="${prayer_times[i]}"
        next_prayer_name="${prayer_names[i]}"
        break
    fi
done
# If no next prayer found today, it means the next prayer is tomorrow's Fajr
if [[ -z "$next_prayer" ]]; then
    next_prayer="${prayer_times[0]}"
    next_prayer_name="${prayer_names[0]}"
    # Add 24 hours to calculation
    next_prayer_seconds=$(date -d "tomorrow $next_prayer" +%s)
else
    # Calculate time difference for today
    next_prayer_seconds=$(date -d "today $next_prayer" +%s)
fi
# Get current time in seconds
current_seconds=$(date +%s)
# Calculate time difference in seconds
time_left_seconds=$((next_prayer_seconds - current_seconds))
# Calculate hours and minutes accurately
hours=$((time_left_seconds / 3600))
minutes=$(((time_left_seconds % 3600) / 60))
# Output just the value without JSON formatting
echo "$next_prayer_name in $(printf "%02d:%02d" "$hours" "$minutes")"
