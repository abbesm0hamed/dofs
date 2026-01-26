#!/bin/bash

if ! command -v makoctl >/dev/null 2>&1; then
    echo '{"text":"","tooltip":"","class":"disabled"}'
    exit 0
fi

count=$(makoctl history 2>/dev/null | grep -c '^Notification ' || true)
count=${count:-0}

if [ "$count" -gt 0 ] 2>/dev/null; then
    echo "{\"text\":\"󰂞 ${count}\", \"tooltip\":\"Notification history: ${count}\", \"class\":\"history\"}"
else
    echo '{"text":"󰂞","tooltip":"Notification history: empty","class":"empty"}'
fi
