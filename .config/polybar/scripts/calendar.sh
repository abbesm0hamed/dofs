#!/bin/bash

# Get current date
TODAY=$(date '+%-d')
MONTH=$(date '+%B %Y')

# Check if cal command exists
if ! command -v cal &> /dev/null; then
    echo "Error: 'cal' command not found"
    exit 1
fi

# Check if rofi exists
if ! command -v rofi &> /dev/null; then
    echo "Error: 'rofi' command not found"
    exit 1
fi

# Generate calendar with highlighted current date
(
echo "$MONTH"
echo ""
cal | sed -e "s/\b${TODAY}\b/*${TODAY}*/"
) | rofi \
    -dmenu \
    -location 2 \
    -yoffset 40 \
    -lines 8 \
    -fixed-num-lines \
    -hide-scrollbar \
    -theme-str 'window {background-color: #1F1F28; border: 2px; border-color: #2D4F67; border-radius: 4px; width: 230px;}' \
    -theme-str 'listview {background-color: #1F1F28; width: 230px;}' \
    -theme-str 'entry {enabled: false;}' \
    -theme-str 'textbox {background-color: #1F1F28;}' \
    -theme-str 'element {text-color: #DCD7BA;}' \
    -theme-str 'element selected {background-color: #2D4F67;}' \
    -theme-str 'element {font: "JetBrainsMono Nerd Font 10";}' \
    -theme-str 'window {padding: 8px;}' \
    -theme-str 'listview {lines: 8; fixed-height: true;}' \
    -no-custom \
    -theme-str 'inputbar {enabled: false;}' \
    > /dev/null 2>&1
