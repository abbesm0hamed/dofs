#!/bin/bash
# Connect to a WiFi network chosen from the launcher. Open networks connect
# directly; secured networks open the connection editor instead of failing on
# a missing password, since the launcher cannot prompt.
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

ssid=$1
security=${2:-}
[[ -n $ssid ]] || { echo "no SSID given" >&2; exit 1; }

if [[ -z $security ]]; then
    exec nmcli device wifi connect "$ssid"
fi
exec nm-connection-editor
