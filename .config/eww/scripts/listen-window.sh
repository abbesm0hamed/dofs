#!/bin/bash

find_in_folder() {
    desktopfile=$(find "$1" -type f,l -iname "$wm_class.desktop" | head -1)
    [[ -z "$desktopfile" ]] && desktopfile=$(find "$1" -type f -name "*.desktop" \
        | xargs grep -L '^NoDisplay=true' \
        | xargs grep -l -i -E "^(Exec|Categories|StartupWMClass).*$wm_class" \
        | head -1);
    [[ -n "$desktopfile" ]] && awk -F= '/^Name=/ {print $2; exit}' "$desktopfile"
}

get_window() {
    xpropid=$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)
    [[ "$xpropid" == "0x0" || "$xpropid" == "" ]] && echo "" && return

    wm_class=$(xprop -id "$xpropid" WM_CLASS | awk '{print $NF}' | tr -d '"')
    [[ "$wm_class" == "found." ]] && echo $(xprop -id "$xpropid" _NET_WM_NAME | cut -d '"' -f 2) && return
    [[ "$wm_class" == "stalonetray" ]] && return

    # Handle if cache file/folders are missing
    [[ ! -d "$HOME/.cache" ]] && mkdir "$HOME/.cache";

    desktopname=$(grep "$wm_class=" "$HOME/.cache/xwindowdesktop" | head -1 | cut -d "=" -f2)
    [[ -z "$desktopname" ]] && desktopname=$(find_in_folder "/usr/share/applications")
    [[ -z "$desktopname" ]] && desktopname=$(find_in_folder "$HOME/.local/share/applications")
    [[ -z "$desktopname" ]] && desktopname=$wm_class

    # Write to cache
    grep -q "$wm_class=" "$HOME/.cache/xwindowdesktop" \
        || echo "$wm_class=$desktopname" >> "$HOME/.cache/xwindowdesktop"

    # Output
    echo $desktopname
}

get_window;
xev -root -event property |
while read -r line; do
    echo $line | grep -q _NET_ACTIVE_WINDOW && get_window
done
