#!/bin/bash
if pgrep -x "wlsunset" >/dev/null; then
  pkill wlsunset
  notify-send "Night Mode" "Disabled"
else
  wlsunset -t 4000 -T 6500 &
  notify-send "Night Mode" "Enabled"
fi
