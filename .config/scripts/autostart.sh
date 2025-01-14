#!/bin/bash

function run {
    if ! pgrep $1; then
        "$@" &
    fi
}

BACKGROUND_PRIMARY="$HOME/.config/backgrounds/owl.jpg"
BACKGROUND_SECONDARY="$HOME/.config/backgrounds/bird.jpg"
PICOM_CONFIG="$HOME/.config/picom/picom.conf"

# Function to check if the second monitor (HDMI-1-0) is connected
function is_second_monitor_connected {
    xrandr | grep "HDMI-1-0 connected" >/dev/null
}

# Function to get the name of the current primary display
function get_current_primary {
    xrandr | grep "primary" | cut -d" " -f1
}

# Function to set up the display configurations and handle workspace transitions
function setup_displays_and_workspaces {
    local current_primary=$(get_current_primary)
    local new_primary
    local current_workspace=$(i3-msg -t get_workspaces | jq '.[] | select(.focused==true).name' -r)

    if is_second_monitor_connected; then
        new_primary="HDMI-1-0"
        xrandr --output HDMI-1-0 --mode 1920x1080 --pos 1920x0 --rate 170 --rotate normal \
            --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal
    else
        new_primary="eDP-1"
        xrandr --output eDP-1 --mode 1920x1080 --pos 0x0 --rotate normal --output HDMI-1-0 --off
    fi

    if [ "$current_primary" != "$new_primary" ]; then
        xrandr --output $new_primary --primary

        # Move all workspaces to the new primary display
        for i in $(seq 1 10); do
            i3-msg "workspace $i; move workspace to output $new_primary"
        done
    fi

    # Restore the previously active workspace
    i3-msg "workspace $current_workspace"
}

# Main execution
setup_displays_and_workspaces

# xrandr --output DP-1 --off --output DP-2 --mode 1920x1080 --pos 1920x415 --rotate normal --output DP-3 --primary --mode 1920x1080 --pos 0x884 --rotate normal --output HDMI-1 --mode 1920x1080 --pos 1920x1495 --rotate normal
run xrandr --output HDMI-1-0 --primary --mode 1920x1080 --pos 1920x0 --rate 170 --rotate normal --output HDMI-2-0 --off

# the backgrounds below match more darker themes like moonfly
# run feh --bg-fill $HOME/.config/backgrounds/store.jpg --bg-fill $HOME/.config/backgrounds/japan.jpg
#
# the backgrounds below matches the kanagawa theme
run feh --no-fehbg --bg-fill "$BACKGROUND_PRIMARY" --bg-fill "$BACKGROUND_SECONDARY" &

run killall polybar picom
# polybar
run ~/.config/polybar/launch_polybar.sh
# compositor
while pgrep -u $UID -x picom >/dev/null; do sleep 1; done
run picom --config ~/.config/picom/picom.conf --vsync

# run ~/.config/eww/launch.sh

#run dex $HOME/.config/autostart/arcolinux-welcome-app.desktop
#autorandr horizontal
#run caffeine
# run stalonetray
run pamac-tray
run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
run xfce4-power-manager
run blueberry-tray
run blueman-applet
run nm-applet
run numlockx on
run volumeicon
run autotiling
run dunst
run variety
run flameshot

# run conky -c $HOME/.config/conky/conky.conf
# you can set wallpapers in themes as well
# run feh --bg-fill $HOME/.config/awesome/themes/mytheme/wallpapers/pineforest2.jpg --bg-fill $HOME/.config/awesome/themes/mytheme/wallpapers/pineforest1.jpg
# run nitrogen --restore
#
#sxhkd
run sxhkd -c "$HOME/.config/sxhkd/sxhkdrc"
