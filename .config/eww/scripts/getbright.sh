#!/bin/bash

typeset -i b=$(cat /sys/class/backlight/intel_backlight/brightness)

echo $(( b / 4 ))
