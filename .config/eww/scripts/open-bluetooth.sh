#!/bin/bash
show_bluetooth() {
  eww update bluetoothopen=true
  eww open bluetooth
}

hide_bluetooth() {
    eww update bluetoothopen=false;
    eww close bluetooth
}

if [[ $1 == false ]]; then
    show_bluetooth
    i3-msg -t subscribe '["window"]' > /dev/null && hide_bluetooth
else
    hide_bluetooth
fi