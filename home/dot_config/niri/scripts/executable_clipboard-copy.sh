#!/bin/bash
# Decode one cliphist entry (matched by its id, the field before the first tab)
# and put it back on the clipboard. Invoked by the launcher as a single argv.
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

id=$1
[[ -n $id ]] || { echo "no clipboard id given" >&2; exit 1; }

cliphist list | awk -F'\t' -v target="$id" '$1 == target { print; exit }' | cliphist decode | wl-copy
command -v notify-send >/dev/null 2>&1 && notify-send "Clipboard" "Item copied to clipboard" || true
