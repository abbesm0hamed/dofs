#!/bin/sh

pactl get-sink-volume $(pactl get-default-sink) | awk -F '[^0-9]+' '/left:/{print $3}'
