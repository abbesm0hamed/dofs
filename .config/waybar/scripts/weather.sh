#!/bin/bash

# Get weather data from wttr.in
weather_data=$(curl -s "wttr.in/?format=%t+%C" 2>/dev/null)

if [ -z "$weather_data" ]; then
  echo '{"text": "Weather unavailable", "tooltip": "Unable to fetch weather data"}'
else
  # Clean up the data
  temp=$(echo "$weather_data" | cut -d' ' -f1)
  condition=$(echo "$weather_data" | cut -d' ' -f2-)
  
  echo "{\"text\": \"$temp\", \"tooltip\": \"$condition\"}"
fi
