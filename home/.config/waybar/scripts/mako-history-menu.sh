#!/bin/bash

if ! command -v makoctl >/dev/null 2>&1 || ! command -v fuzzel >/dev/null 2>&1; then
    exit 0
fi

history=$(makoctl history 2>/dev/null || true)

if [ -z "$history" ]; then
    printf '%s\n' "No notification history" | fuzzel --dmenu --prompt="󰂞 History: " --width=35 --lines=1 >/dev/null
    exit 0
fi

choice=$(printf '%s' "$history" | awk 'BEGIN { RS="Notification "; FS="\n" } NR>1 {
    split($1, a, ": ");
    id=a[1];
    title=a[2];
    app="";
    for (i=2; i<=NF; i++) {
        if ($i ~ /^  App name: /) {
            app=$i;
            sub(/^  App name: /, "", app);
            break;
        }
    }
    line=title;
    if (app != "") line=line " (" app ")";
    printf "%s\t%s\n", id, line;
}' | fuzzel --dmenu --prompt="󰂞 History: " --width=60 --lines=10)

[ -z "$choice" ] && exit 0

id=$(printf '%s' "$choice" | cut -f1)
[ -z "$id" ] && exit 0

tmp=$(mktemp)
printf '%s' "$history" | awk -v target="$id" 'BEGIN { RS="Notification "; ORS="" } NR>1 {
    split($1, a, ": ");
    if (a[1] == target) {
        print "Notification " $0;
    }
}' > "$tmp"

if command -v ghostty >/dev/null 2>&1; then
    ghostty -e sh -c "less '$tmp'; rm -f '$tmp'"
else
    sh -c "less '$tmp'; rm -f '$tmp'"
fi
