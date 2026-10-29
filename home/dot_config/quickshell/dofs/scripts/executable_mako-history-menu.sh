#!/bin/bash
# Notification history provider for the dofs Quickshell launcher.
# Provider: one JSON item per missed notification; activation opens the
# full notification text in a pager.
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
. "$HOME/.config/niri/scripts/menu-lib.sh"

command -v makoctl >/dev/null 2>&1 || { echo "makoctl not found" >&2; exit 1; }

history=$(makoctl history 2>/dev/null || true)
if [ -z "$history" ]; then
    echo "no notification history" >&2
    exit 1
fi

tmp=$(mktemp)
printf '%s' "$history" > "$tmp"

count=0
while IFS=$'\t' read -r id title; do
    [[ -n $id ]] || continue
    count=$((count + 1))
    menu_item "$title" "View notification" "preferences-system-notifications" \
        -- ghostty -e sh -c 'less "$1"; rm -f "$1"' sh "$tmp"
done < <(printf '%s' "$history" | awk 'BEGIN { RS="Notification "; FS="\n" } NR>1 {
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
}')

[[ $count -gt 0 ]] || { rm -f "$tmp"; echo "no notification history" >&2; exit 1; }
