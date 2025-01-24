#!/bin/bash

# Fetch current location using IP-based geolocation
LOCATION=$(curl -s http://ip-api.com/json | jq -r '.lat,.lon' | paste -sd, -)

# Check if location data is available
if [ -z "$LOCATION" ] || [ "$LOCATION" = "null" ]; then
    echo "%{F#ff0000} Location unavailable%{F-}"
    exit 1
fi

# Extract latitude and longitude
latitude=$(echo "$LOCATION" | cut -d',' -f1)
longitude=$(echo "$LOCATION" | cut -d',' -f2)

# Prayer names in order
declare -a prayer_names=("Fajr" "Dhuhr" "Asr" "Maghrib" "Isha")

# Get current time in 24-hour format
current_time=$(date +%H:%M)

# Fetch prayer times from API
prayer_data=$(curl -s "http://api.aladhan.com/v1/calendar/$(date +%Y)/$(date +%m)?latitude=$latitude&longitude=$longitude&method=3")

# Check if curl request was successful
if [ -z "$prayer_data" ] || ! echo "$prayer_data" | jq -e '.data' >/dev/null; then
    echo "%{F#ff0000} Prayer times unavailable%{F-}"
    exit 1
fi

# Extract prayer times for today using jq
day_data=$(echo "$prayer_data" | jq -r ".data[$(($(date +%-d) - 1))]")
if [ -z "$day_data" ] || [ "$day_data" = "null" ]; then
    echo "%{F#ff0000} Prayer times unavailable%{F-}"
    exit 1
fi

# Get prayer times
fajr=$(echo "$day_data" | jq -r '.timings.Fajr' | cut -d' ' -f1)
dhuhr=$(echo "$day_data" | jq -r '.timings.Dhuhr' | cut -d' ' -f1)
asr=$(echo "$day_data" | jq -r '.timings.Asr' | cut -d' ' -f1)
maghrib=$(echo "$day_data" | jq -r '.timings.Maghrib' | cut -d' ' -f1)
isha=$(echo "$day_data" | jq -r '.timings.Isha' | cut -d' ' -f1)

# Store times in array
prayer_times=("$fajr" "$dhuhr" "$asr" "$maghrib" "$isha")

# Find the next prayer
next_prayer=""
next_prayer_name=""
for i in "${!prayer_times[@]}"; do
    if [[ "${prayer_times[$i]}" > "$current_time" ]]; then
        next_prayer="${prayer_times[$i]}"
        next_prayer_name="${prayer_names[$i]}"
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

# Output in a nice format with polybar color formatting (removed the left bar separator)
printf "%%{F#7E9CD8}%s in %02d:%02d%%{F-}" "$next_prayer_name" "$hours" "$minutes"
