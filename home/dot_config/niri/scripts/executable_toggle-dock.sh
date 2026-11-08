#!/bin/bash

# Toggle the Quickshell dock. crystal-dock was a separate daemon; the dock now
# lives in the quickshell shell (dot_config/quickshell/dofs/dock).
timeout --kill-after=1s 2s qs -c dofs ipc call dock toggle \
    || notify-send --urgency=critical 'Dock unavailable' \
        'The quickshell dock did not respond: qs -c dofs kill; then restart it.'
