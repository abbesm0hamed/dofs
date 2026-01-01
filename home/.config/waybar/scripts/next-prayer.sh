#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================
# Set your location manually for best accuracy.
# If left empty, the script will attempt to detect location via IP (less accurate).
LATITUDE=""
LONGITUDE=""

# Calculation Method
# 1 - University of Islamic Sciences, Karachi
# 2 - Islamic Society of North America
# 3 - Muslim World League (Standard for Europe/US often)
# 4 - Umm al-Qura University, Makkah
# 5 - Egyptian General Authority of Survey
# 12 - Union Organization islamic de France
# 13 - Diyanet İşleri Başkanlığı, Turkey
# See http://api.aladhan.com/v1/methods for full list.
METHOD=3

# Cache File
CACHE_DIR="/tmp/prayer_times_cache"
mkdir -p "$CACHE_DIR"

MAX_RETRIES=3
RETRY_DELAY=2

# ==============================================================================
# FUNCTIONS
# ==============================================================================

# Check if required commands are available
check_deps() {
    for cmd in curl jq date; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "$cmd not found"
            exit 1
        fi
    done
}

# Fetch location if not manually set
get_location() {
    if [ -n "$LATITUDE" ] && [ -n "$LONGITUDE" ]; then
        return 0
    fi

    local cache_file="${CACHE_DIR}/location.json"
    
    # Use cached location if it exists and is not empty
    if [ -f "$cache_file" ] && [ -s "$cache_file" ]; then
        LATITUDE=$(jq -r '.lat' "$cache_file")
        LONGITUDE=$(jq -r '.lon' "$cache_file")
        return 0
    fi

    for ((i = 1; i <= MAX_RETRIES; i++)); do
        loc_json=$(curl -s --connect-timeout 5 http://ip-api.com/json)
        if [ $? -eq 0 ] && echo "$loc_json" | jq -e '.lat' >/dev/null; then
            LATITUDE=$(echo "$loc_json" | jq -r '.lat')
            LONGITUDE=$(echo "$loc_json" | jq -r '.lon')
            echo "$loc_json" > "$cache_file"
            return 0
        fi
        sleep $RETRY_DELAY
    done
    return 1
}

# Fetch monthly calendar
fetch_calendar_data() {
    local year=$1
    local month=$2
    local cache_file="${CACHE_DIR}/calendar_${year}_${month}.json"

    # Use cache if exists
    if [ -f "$cache_file" ] && [ -s "$cache_file" ]; then
        cat "$cache_file"
        return 0
    fi

    # Fetch from API
    for ((i = 1; i <= MAX_RETRIES; i++)); do
        data=$(curl -s --connect-timeout 5 "http://api.aladhan.com/v1/calendar/${year}/${month}?latitude=${LATITUDE}&longitude=${LONGITUDE}&method=${METHOD}")
        if [ $? -eq 0 ] && echo "$data" | jq -e '.data' >/dev/null; then
            echo "$data" > "$cache_file"
            echo "$data"
            return 0
        fi
        sleep $RETRY_DELAY
    done
    return 1
}

# Fetch single day timings (useful for month rollover)
fetch_single_day() {
    local date_str=$1 # Format: DD-MM-YYYY
    local cache_file="${CACHE_DIR}/timings_${date_str}.json"

     if [ -f "$cache_file" ] && [ -s "$cache_file" ]; then
        cat "$cache_file"
        return 0
    fi

    for ((i = 1; i <= MAX_RETRIES; i++)); do
        # Convert date to timestamp for the API or use timingsByDate
        # API expects DD-MM-YYYY
        data=$(curl -s --connect-timeout 5 "http://api.aladhan.com/v1/timings/${date_str}?latitude=${LATITUDE}&longitude=${LONGITUDE}&method=${METHOD}")
        if [ $? -eq 0 ] && echo "$data" | jq -e '.data' >/dev/null; then
             echo "$data" > "$cache_file"
             echo "$data"
             return 0
        fi
        sleep $RETRY_DELAY
    done
    return 1
}

# ==============================================================================
# MAIN LOGIC
# ==============================================================================

check_deps
get_location

if [ -z "$LATITUDE" ] || [ -z "$LONGITUDE" ]; then
    echo "Location unavailable"
    exit 1
fi

# Current date details
current_year=$(date +%Y)
current_month=$(date +%m)
current_day=$(date +%d) # 01-31
current_day_idx=$((10#$current_day - 1)) # 0-indexed for array
current_time=$(date +%H:%M)

# Fetch data for current month
calendar_data=$(fetch_calendar_data "$current_year" "$current_month")
if [ -z "$calendar_data" ]; then
    echo "Data unavailable"
    exit 1
fi

declare -a prayer_names=("Fajr" "Dhuhr" "Asr" "Maghrib" "Isha")
prayer_times=()

# Parse today's times
for prayer in "${prayer_names[@]}"; do
    # Extract time (HH:MM) cleaning any extra info like (CET)
    t=$(echo "$calendar_data" | jq -r ".data[$current_day_idx].timings.$prayer" | cut -d' ' -f1)
    prayer_times+=("$t")
done

next_prayer=""
next_prayer_name=""
next_prayer_time_str=""

# Find next prayer today
for i in "${!prayer_times[@]}"; do
    if [[ "${prayer_times[i]}" > "$current_time" ]]; then
        next_prayer_time_str="${prayer_times[i]}"
        next_prayer_name="${prayer_names[i]}"
        next_prayer_seconds=$(date -d "${next_prayer_time_str}" +%s)
        break
    fi
done

# If no prayer left today, get tomorrow's Fajr
if [[ -z "$next_prayer_name" ]]; then
    next_prayer_name="Fajr"
    
    # Check if tomorrow is in next month
    tomorrow_date=$(date -d "tomorrow" +%d-%m-%Y)
    tomorrow_day=$(date -d "tomorrow" +%d)
    
    # If tomorrow is the 1st, we might need next month's data or just a single day fetch
    if [ "$tomorrow_day" == "01" ]; then
        # Fetch specifically for tomorrow to be accurate across month boundaries
        next_day_data=$(fetch_single_day "$tomorrow_date")
        if [ -n "$next_day_data" ]; then
             next_prayer_time_str=$(echo "$next_day_data" | jq -r ".data.timings.Fajr" | cut -d' ' -f1)
        else
            # Fallback: use today's Fajr 
             next_prayer_time_str="${prayer_times[0]}"
        fi
    else
        # Just use the next index in the current month array
        # Using tomorrow's day index (which is today's index + 1)
        next_day_idx=$((current_day_idx + 1))
        next_prayer_time_str=$(echo "$calendar_data" | jq -r ".data[$next_day_idx].timings.Fajr" | cut -d' ' -f1)
        
        # Safety check if jq returns null (shouldn't happen if calendar has correct days)
        if [ -z "$next_prayer_time_str" ] || [ "$next_prayer_time_str" == "null" ]; then
             next_prayer_time_str="${prayer_times[0]}"
        fi
    fi
    
    # Calculate seconds for tomorrow
    next_prayer_seconds=$(date -d "tomorrow $next_prayer_time_str" +%s)
fi


# Output result
current_seconds=$(date +%s)
time_left_seconds=$((next_prayer_seconds - current_seconds))

if [ $time_left_seconds -lt 0 ]; then
    # Should not happen with correct logic, but fallback
    echo "Calculating..."
    exit 0
fi

# Notification Logic
ALERT_THRESHOLD=300 # 5 minutes in seconds
STATE_FILE="/tmp/prayer_alert_sent"

# If time left is less than 5 minutes (but more than 4, to catch it in a 60s interval)
if [ $time_left_seconds -le $ALERT_THRESHOLD ] && [ $time_left_seconds -gt 240 ]; then
    CURRENT_PRAYER_ID="${next_prayer_name}_$(date +%F)"
    LAST_NOTIFIED=$(cat "$STATE_FILE" 2>/dev/null || echo "")
    
    if [ "$LAST_NOTIFIED" != "$CURRENT_PRAYER_ID" ]; then
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -u critical "Prayer Alert" "5 minutes until $next_prayer_name ($next_prayer_time_str)" -i appointment-soon
            echo "$CURRENT_PRAYER_ID" > "$STATE_FILE"
        fi
    fi
fi

hours=$((time_left_seconds / 3600))
minutes=$(((time_left_seconds % 3600) / 60))

# Format: "PrayerName in HH:MM"
echo "$next_prayer_name in $(printf "%02d:%02d" "$hours" "$minutes")"
