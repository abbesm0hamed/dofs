#!/bin/bash

# Get the CPU temperature
temp=$(sensors | grep 'Package id 0:' | awk '{print $4}')

# Output the temperature
echo "CPU: $temp"
