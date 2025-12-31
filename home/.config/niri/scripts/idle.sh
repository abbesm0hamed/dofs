#!/bin/bash

# Basic swayidle command with timeouts
swayidle -w \
  timeout 300 'brightnessctl s 10%' \
  resume 'brightnessctl s 80%' \
  timeout 600 'niri msg action power-off-monitors' \
  resume 'niri msg action power-on-monitors' \
  timeout 900 'systemctl suspend' \
  before-sleep 'niri msg action power-off-monitors' \
  after-resume 'niri msg action power-on-monitors'
