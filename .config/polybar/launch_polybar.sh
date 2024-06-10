#!/bin/bash

DIR="$HOME/.config/polybar"

killall -q polybar &

while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

for m in $(xrandr --listactivemonitors | grep "+" | cut -d" " -f6); do
  MONITOR=$m polybar -q -r top -c "$DIR"/config.ini &
  MONITOR=$m polybar -q -r bottom -c "$DIR"/config.ini &
done
