#!/usr/bin/env bash
# Shared emitter for dofs Quickshell launcher menu providers.
#
# A provider script prints one JSON object per line describing each menu item;
# the launcher renders them and runs the chosen argv through launch.py.
# Providers must print nothing except these lines (stderr carries errors).
#
# Usage in a provider:
#   . "$HOME/.config/niri/scripts/menu-lib.sh"
#   menu_item NAME DESCRIPTION ICON -- ARG...       # runnable item
#   menu_item NAME DESCRIPTION ICON --menu SCRIPT   # nested submenu provider
#   menu_item NAME DESCRIPTION ICON --copy TEXT     # info item; Enter copies

menu_item() {
    local name=$1 description=$2 icon=$3
    shift 3
    case ${1:-} in
        "--menu")
            shift
            jq -cn --arg n "$name" --arg d "$description" --arg i "$icon" --arg m "$1" \
                '{name:$n, description:$d, icon:$i, menu:[$m]}'
            ;;
        "--copy")
            shift
            jq -cn --arg n "$name" --arg d "$description" --arg i "$icon" --arg c "$1" \
                '{name:$n, description:$d, icon:$i, copy:$c}'
            ;;
        "--")
            shift
            # The extra "--" stops jq from misreading args like "--run" as options.
            jq -cn --arg n "$name" --arg d "$description" --arg i "$icon" \
                '{name:$n, description:$d, icon:$i, command:$ARGS.positional}' --args -- "$@"
            ;;
        *)
            echo "menu_item: expected --, --menu or --copy" >&2
            return 1
            ;;
    esac
}
