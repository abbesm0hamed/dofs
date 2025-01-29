#!/bin/bash

# Function to fetch location with retries
get_location() {
  local max_attempts=3
  local attempt=1
  local wait_time=5 # seconds between retries

  while [ $attempt -le $max_attempts ]; do
    LOCATION=$(curl -s http://ip-api.com/json | jq -r '.lat,.lon' | paste -sd, -)

    if [ -n "$LOCATION" ] && [ "$LOCATION" != "null" ]; then
      return 0
    fi

    echo "Attempt $attempt of $max_attempts: Location unavailable, retrying in $wait_time seconds..." >&2
    sleep $wait_time
    attempt=$((attempt + 1))
  done

  return 1
}

# Function to fetch weather data with retries
get_weather() {
  local lat=$1
  local lon=$2
  local max_attempts=3
  local attempt=1
  local wait_time=5 # seconds between retries

  while [ $attempt -le $max_attempts ]; do
    # Try Open-Meteo first
    WEATHER_DATA=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true")

    if [ -n "$WEATHER_DATA" ] && echo "$WEATHER_DATA" | jq -e '.current_weather' >/dev/null; then
      return 0
    fi

    # If Open-Meteo fails, try wttr.in
    WEATHER_DATA=$(curl -s "wttr.in/?format=j1")

    if [ -n "$WEATHER_DATA" ] && echo "$WEATHER_DATA" | jq -e '.current_condition[0]' >/dev/null; then
      return 0
    fi

    echo "Attempt $attempt of $max_attempts: Weather data unavailable, retrying in $wait_time seconds..." >&2
    sleep $wait_time
    attempt=$((attempt + 1))
  done

  return 1
}

# Try to get location
if ! get_location; then
  echo "󰖙 Location unavailable" # Default icon and message
  exit 1
fi

# Extract latitude and longitude
LAT=$(echo "$LOCATION" | cut -d',' -f1)
LON=$(echo "$LOCATION" | cut -d',' -f2)

# Try to get weather data
if ! get_weather "$LAT" "$LON"; then
  echo "󰖙 Weather data unavailable" # Default icon and message
  exit 1
fi

# Parse weather data based on which service succeeded
if echo "$WEATHER_DATA" | jq -e '.current_weather' >/dev/null; then
  # Parse weather data from Open-Meteo
  TEMP=$(echo "$WEATHER_DATA" | jq -r '.current_weather.temperature')
  WEATHER_CODE=$(echo "$WEATHER_DATA" | jq -r '.current_weather.weathercode')
else
  # Parse weather data from wttr.in
  TEMP=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].temp_C')
  WEATHER_CODE=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].weatherCode')
fi

# Map weather codes to Nerd Fonts or Unicode symbols
case $WEATHER_CODE in
0)
  ICON=""
  WEATHER="Clear"
  ;; # Clear sky
1 | 2 | 3)
  ICON=""
  WEATHER="Cloudy"
  ;; # Mainly clear, partly cloudy
45 | 48)
  ICON=""
  WEATHER="Fog"
  ;; # Fog
51 | 53 | 55)
  ICON=""
  WEATHER="Drizzle"
  ;; # Drizzle
56 | 57)
  ICON=""
  WEATHER="Freezing Drizzle"
  ;;
61 | 63 | 65)
  ICON=""
  WEATHER="Rain"
  ;; # Rain
66 | 67)
  ICON=""
  WEATHER="Freezing Rain"
  ;;
71 | 73 | 75)
  ICON=""
  WEATHER="Snow"
  ;; # Snow
77)
  ICON=""
  WEATHER="Snow Grains"
  ;;
80 | 81 | 82)
  ICON=""
  WEATHER="Showers"
  ;; # Showers
85 | 86)
  ICON=""
  WEATHER="Snow Showers"
  ;;
95 | 96 | 99)
  ICON=""
  WEATHER="Thunderstorm"
  ;; # Thunderstorm
*)
  ICON=""
  WEATHER="Unknown"
  ;; # Default icon
esac

# Display weather in Polybar
echo "$ICON $TEMP°C $WEATHER"
