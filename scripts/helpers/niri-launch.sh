#!/bin/bash

# Source env variables (Bash syntax)
if [ -f "$HOME/.config/niri/configs/env" ]; then
    set -a
    source "$HOME/.config/niri/configs/env"
    set +a
fi

# Launch Niri
exec niri --session
