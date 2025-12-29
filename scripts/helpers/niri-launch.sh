#!/bin/bash

# Source env variables (Bash syntax)
if [ -f "$HOME/.config/niri/env" ]; then
    set -a
    source "$HOME/.config/niri/env"
    set +a
fi

# Launch Niri
exec niri --session
