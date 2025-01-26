#!/bin/bash

get_temp() {
    # Get the first temperature reading we can find
    temp=$(sensors 2>/dev/null | grep -E "°C|deg C" | grep -oE "[0-9]+\.[0-9]+" | head -n1)
    if [ -n "$temp" ]; then
        printf "%.0f" "$temp"
    else
        echo "N/A"
    fi
}

get_top_process() {
    ps -eo pcpu,comm --no-headers | sort -nr | head -n 1
}

temp=$(get_temp)
top_proc=$(get_top_process)
top_proc_name=$(echo "$top_proc" | awk '{print $2}')
top_proc_cpu=$(echo "$top_proc" | awk '{printf "%.1f", $1}')

# Use different icons based on temperature
if [ "$temp" = "N/A" ]; then
    temp_icon="%{T3}󱃃%{T-}"
elif [ "$temp" -lt 50 ]; then
    temp_icon="%{T3}󱃃%{T-}"  # cool
elif [ "$temp" -lt 70 ]; then
    temp_icon="%{T3}󰸁%{T-}"  # warm
else
    temp_icon="%{T3}󱃂%{T-}"  # hot
fi

# Format the process name to be at most 15 chars
if [ ${#top_proc_name} -gt 15 ]; then
    top_proc_name="%{T5}${top_proc_name:0:12}%{T-}..."
fi

if [ "$temp" = "N/A" ]; then
    echo "$temp_icon N/A    %{T3}󰾆 %{T-}%{T5}${top_proc_name} (${top_proc_cpu}%)%{T-}"
else
    echo "$temp_icon ${temp}°C    %{T3}󰾆 %{T-}%{T5}${top_proc_name} (${top_proc_cpu}%)%{T-}"
fi
