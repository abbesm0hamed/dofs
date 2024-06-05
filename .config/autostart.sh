#!/bin/bash

function run {
	if ! pgrep $1; then
		$@ &
	fi
}

run nm-applet
run xrandr --output HDMI-1-0 --primary --mode 1920x1080 --pos 1920x0 --rate 170 --rotate normal --output HDMI-2-0 --off
#run xrandr --output VGA-1 --primary --mode 1360x768 --pos 0x0 --rotate normal
#run dex $HOME/.config/autostart/arcolinux-welcome-app.desktop
#autorandr horizontal
#run caffeine
run sxhkd -c $HOME/.config/qtile/sxhkd/sxhkdrc &
picom --config $HOME/.config/picom/picom.conf &
/usr/bin/dunst &
run pamac-tray
# run variety
run xfce4-power-manager
run blueberry-tray
run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
run numlockx on
run volumeicon
# run conky -c $HOME/.config/conky/conky.conf
#you can set wallpapers in themes as well
run feh --bg-fill $HOME/.config/backgrounds/street.jpg --bg-fill $HOME/.config/backgrounds/japan.jpg &
# run feh --bg-fill $HOME/.config/awesome/themes/mytheme/wallpapers/pineforest2.jpg --bg-fill $HOME/.config/awesome/themes/mytheme/wallpapers/pineforest1.jpg &
# run nitrogen --restore &
#run applications from startup
# run brave
# run wezterm
#run atom
#run dropbox
#run insync start
#run spotify
#run ckb-next -b
#run discord --start-minimized &
#run telegram-desktop
