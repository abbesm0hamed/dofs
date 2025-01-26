#!/bin/bash

quote=$(curl -s "https://api.adviceslip.com/advice" | jq -r '.slip.advice')
notify-send "Daily Motivation" "$quote" -u normal