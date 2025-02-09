#!/bin/bash
# Function to display formatted output
show_weather() {
  local icon=$1
  local message=$2
  echo "$icon $message"
}

# Function to handle errors
handle_error() {
  echo "{\"text\": \"$1\", \"tooltip\": \"Error: $1\"}"
  exit 1
}

# Add timeout to curl commands
CURL_OPTS="-s --max-time 5"

# Try to fetch location with retries
for i in {1..3}; do
  LOCATION=$(curl $CURL_OPTS http://ip-api.com/json | jq -r '.lat,.lon' | paste -sd, -)
  if [ -n "$LOCATION" ] && [ "$LOCATION" != "null" ]; then
    break
  fi
  sleep 1
done

# Check if location data is available
if [ -z "$LOCATION" ] || [ "$LOCATION" = "null" ]; then
  handle_error "Connecting..."
fi

# Extract latitude and longitude
LAT=$(echo "$LOCATION" | cut -d',' -f1)
LON=$(echo "$LOCATION" | cut -d',' -f2)

# Try Open-Meteo first, then wttr.in as fallback
WEATHER_DATA=$(curl $CURL_OPTS "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current_weather=true")
if [ -n "$WEATHER_DATA" ] && echo "$WEATHER_DATA" | jq -e '.current_weather' >/dev/null 2>&1; then
  TEMP=$(echo "$WEATHER_DATA" | jq -r '.current_weather.temperature')
  WEATHER_CODE=$(echo "$WEATHER_DATA" | jq -r '.current_weather.weathercode')
else
  # Fallback to wttr.in
  WEATHER_DATA=$(curl $CURL_OPTS "wttr.in/?format=j1")
  if [ -z "$WEATHER_DATA" ] || ! echo "$WEATHER_DATA" | jq -e '.current_condition[0]' >/dev/null 2>&1; then
    handle_error "No data"
  fi
  TEMP=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].temp_C')
  WEATHER_CODE=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].weatherCode')
fi

# Map weather codes to icons (same as before)
case $WEATHER_CODE in
0)
  ICON="󰖙"
  WEATHER="Clear"
  ;; # Clear sky
1 | 2 | 3)
  ICON="󰖐"
  WEATHER="Cloudy"
  ;; # Mainly clear, partly cloudy
45 | 48)
  ICON="󰖑"
  WEATHER="Fog"
  ;; # Fog
51 | 53 | 55)
  ICON="󰖗"
  WEATHER="Drizzle"
  ;; # Drizzle
56 | 57)
  ICON="󰙿"
  WEATHER="Freezing Drizzle"
  ;;
61 | 63 | 65)
  ICON="󰖖"
  WEATHER="Rain"
  ;; # Rain
66 | 67)
  ICON="󰖒"
  WEATHER="Freezing Rain"
  ;;
71 | 73 | 75)
  ICON="󰖘"
  WEATHER="Snow"
  ;; # Snow
77)
  ICON="󰼶"
  WEATHER="Snow Grains"
  ;;
80 | 81 | 82)
  ICON="󰖖"
  WEATHER="Showers"
  ;; # Showers
85 | 86)
  ICON="󰖘"
  WEATHER="Snow Showers"
  ;;
95 | 96 | 99)
  ICON="󰖓"
  WEATHER="Thunderstorm"
  ;; # Thunderstorm
*)
  ICON="󰖛"
  WEATHER="Unknown"
  ;; # Default icon
esac

# Output simple format
echo "$ICON $TEMP°C $WEATHER"
