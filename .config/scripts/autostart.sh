#!/bin/bash

function run {
  if ! pgrep $1; then
    $@ &
  fi
}

run xrandr --output HDMI-1-0 --primary --mode 1920x1080 --pos 1920x0 --rate 170 --rotate normal --output HDMI-2-0 --off
# xrandr --output DP-1 --off --output DP-2 --mode 1920x1080 --pos 1920x415 --rotate normal --output DP-3 --primary --mode 1920x1080 --pos 0x884 --rotate normal --output HDMI-1 --mode 1920x1080 --pos 1920x1495 --rotate normal
#
# compositor
# run killall picom
# while pgrep -u $UID -x picom >/dev/null; do sleep 1; done
# run picom --config ~/.config/picom/picom.conf --vsync 

run ~/.config/polybar/launch_polybar.sh

# run ~/.config/eww/launch.sh

#run dex $HOME/.config/autostart/arcolinux-welcome-app.desktop
#autorandr horizontal
#run caffeine
run autotiling
# run dunst
run pamac-tray
run variety
run xfce4-power-manager
run blueberry-tray
run blueman-applet
run nm-applet
# run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
run numlockx on
run volumeicon
# run flameshot

# run conky -c $HOME/.config/conky/conky.conf
#you can set wallpapers in themes as well
run feh --bg-fill $HOME/.config/backgrounds/street.jpg --bg-fill $HOME/.config/backgrounds/japan.jpg
# run feh --bg-fill $HOME/.config/awesome/themes/mytheme/wallpapers/pineforest2.jpg --bg-fill $HOME/.config/awesome/themes/mytheme/wallpapers/pineforest1.jpg 
# run nitrogen --restore 
#
#sxhkd
run sxhkd -c $HOME/.config/sxhkd/sxhkdrc
