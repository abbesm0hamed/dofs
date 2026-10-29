#!/bin/bash
# Power menu provider for the dofs Quickshell launcher.
# Provider: prints one JSON item per line. The bar and keybindings open this
# entry through quickshell-launcher.sh power.
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
. "$HOME/.config/niri/scripts/menu-lib.sh"

menu_item "Lock screen" "Lock this session" "system-lock-screen" -- hyprlock
menu_item "Log out" "End this niri session" "system-log-out" -- niri msg action quit
menu_item "Suspend" "Sleep until woken" "system-suspend" -- systemctl suspend
menu_item "Reboot" "Restart this machine" "system-reboot" -- systemctl reboot
menu_item "Shut down" "Power off this machine" "system-shutdown" -- systemctl poweroff
