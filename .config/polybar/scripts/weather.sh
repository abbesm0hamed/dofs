#!/bin/bash

# Fetch current location using IP-based geolocation
LOCATION=$(curl -s http://ip-api.com/json | jq -r '.lat,.lon' | paste -sd, -)

# Check if location data is available
if [ -z "$LOCATION" ] || [ "$LOCATION" = "null" ]; then
  echo "󰖙 Location unavailable" # Default icon and message
  exit 1
fi

# Extract latitude and longitude
LAT=$(echo "$LOCATION" | cut -d',' -f1)
LON=$(echo "$LOCATION" | cut -d',' -f2)

# Fetch weather data from Open-Meteo
WEATHER_DATA=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current_weather=true")

# Check if weather data is available
if [ -z "$WEATHER_DATA" ] || ! echo "$WEATHER_DATA" | jq -e '.current_weather' >/dev/null; then
  # Fallback to wttr.in
  WEATHER_DATA=$(curl -s "wttr.in/?format=j1")
  if [ -z "$WEATHER_DATA" ] || ! echo "$WEATHER_DATA" | jq -e '.current_condition[0]' >/dev/null; then
    echo "󰖙 Weather data unavailable" # Default icon and message
    exit 1
  fi
  TEMP=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].temp_C')
  WEATHER_CODE=$(echo "$WEATHER_DATA" | jq -r '.current_condition[0].weatherCode')
else
  # Parse weather data from Open-Meteo
  TEMP=$(echo "$WEATHER_DATA" | jq -r '.current_weather.temperature')
  WEATHER_CODE=$(echo "$WEATHER_DATA" | jq -r '.current_weather.weathercode')
fi

# Map weather codes to Nerd Fonts or Unicode symbols
case $WEATHER_CODE in
0)
  ICON=""
  WEATHER="Clear"
  ;; # Clear sky
1 | 2 | 3)
  ICON=""
  WEATHER="Cloudy"
  ;; # Mainly clear, partly cloudy
45 | 48)
  ICON=""
  WEATHER="Fog"
  ;; # Fog
51 | 53 | 55)
  ICON=""
  WEATHER="Drizzle"
  ;; # Drizzle
56 | 57)
  ICON=""
  WEATHER="Freezing Drizzle"
  ;;
61 | 63 | 65)
  ICON=""
  WEATHER="Rain"
  ;; # Rain
66 | 67)
  ICON=""
  WEATHER="Freezing Rain"
  ;;
71 | 73 | 75)
  ICON=""
  WEATHER="Snow"
  ;; # Snow
77)
  ICON=""
  WEATHER="Snow Grains"
  ;;
80 | 81 | 82)
  ICON=""
  WEATHER="Showers"
  ;; # Showers
85 | 86)
  ICON=""
  WEATHER="Snow Showers"
  ;;
95 | 96 | 99)
  ICON=""
  WEATHER="Thunderstorm"
  ;; # Thunderstorm
*)
  ICON=""
  WEATHER="Unknown"
  ;; # Default icon
esac

# Display weather in Polybar
echo "$ICON $TEMP°C $WEATHER"
