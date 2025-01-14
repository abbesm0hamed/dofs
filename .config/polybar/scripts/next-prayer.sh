#!/bin/bash

# Replace with your location's latitude, longitude, and timezone
latitude=36.7253
longitude=10.2110
timezone=Africa/Tunis

# Calculate prayer times for today
prayers=$(prayertimes --date today --latitude $latitude --longitude $longitude --timezone $timezone | awk '{print $2}')

# Get current time
current_time=$(date +%H:%M)

# Find the next prayer time
next_prayer=""
for prayer in $prayers; do
	if [[ "$prayer" > "$current_time" ]]; then
		next_prayer=$prayer
		break
	fi
done

if [[ -z "$next_prayer" ]]; then
	next_prayer=$(echo "$prayers" | head -n 1)
fi

# Calculate time left until the next prayer
next_prayer_seconds=$(date -d "$next_prayer" +%s)
current_seconds=$(date +%s)
time_left_seconds=$((next_prayer_seconds - current_seconds))
hours=$((time_left_seconds / 3600))
minutes=$(((time_left_seconds % 3600) / 60))

printf "%s in %02d:%02d\n" "$next_prayer" "$hours" "$minutes"
