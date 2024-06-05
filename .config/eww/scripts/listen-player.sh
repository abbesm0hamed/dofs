#!/bin/bash

get_player() {
    if playerctl -p spotify,Feishin metadata &> /dev/null ; then
        title=$(playerctl -p spotify,Feishin metadata -f "{{artist}} - {{title}}" | sed -E 's/(.{40}).+/\1.../')
        playing=$(playerctl -p spotify,Feishin status 2> /dev/null | grep Playing > /dev/null && echo true || echo false)
        out="{\"player\":true,\"title\":\"$title\",\"playing\":$playing}"
    else
        out="{\"player\":false,\"title\":\"No music playing\"}";
    fi

    echo $out
}

get_player;
dbus-monitor \
    "arg0=org.mpris.MediaPlayer2.Feishin" \
    "type=signal,path=/org/mpris/MediaPlayer2,member=PropertiesChanged" |
while read -r line; do
    echo $line | grep -e '^signal'>/dev/null && get_player;
done;
