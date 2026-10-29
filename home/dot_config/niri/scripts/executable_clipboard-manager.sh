#!/bin/bash
# Clipboard history for the dofs Quickshell launcher.
# Provider: one JSON item per cliphist entry; activation restores it.
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
. "$HOME/.config/niri/scripts/menu-lib.sh"

count=0
while IFS=$'\t' read -r id preview; do
    [[ -n $id ]] || continue
    count=$((count + 1))
    label=${preview//$'\n'/ }
    label=${label//\t/ }
    label=${label:0:80}
    menu_item "${label:-ignored entry}" "Restore to clipboard" "edit-paste" \
        -- bash "$HOME/.config/niri/scripts/clipboard-copy.sh" "$id"
done < <(cliphist list 2>/dev/null)

[[ $count -gt 0 ]] || { echo "clipboard history is empty" >&2; exit 1; }
