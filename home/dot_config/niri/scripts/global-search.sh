#!/bin/bash

# Global Search script for Niri
# Launches a terminal to search projects and opens selection in Neovim

PROJECT_ROOTS=("$HOME/projects" "$HOME/Development" "$HOME/src" "$HOME/dofs" "$HOME/Documents/work" "$HOME/Documents/personal")
SEARCH_DIRS=()

for root in "${PROJECT_ROOTS[@]}"; do
    if [ -d "$root" ]; then
        SEARCH_DIRS+=("$root")
    fi
done

if [ ${#SEARCH_DIRS[@]} -eq 0 ]; then
    notify-send "Global Search" "No project directories found."
    exit 1
fi

# We run the selection process INSIDE a terminal because fzf needs a TTY
# The result is written to a temp file, which we then read back
TMP_PICK=$(mktemp)

wezterm start -- bash -c "rg --line-number --column --no-heading --fixed-strings --ignore-case --no-ignore --hidden --follow --glob '!.git/*' '' ${SEARCH_DIRS[*]} \
    | fzf --delimiter : --preview 'bat --color=always --highlight-line {2} {1}' --preview-window '~3,+{2}+4/2' \
    | cut -d: -f1,2,3 > $TMP_PICK"

PICK=$(cat "$TMP_PICK")
rm "$TMP_PICK"

if [ -z "$PICK" ]; then
    exit 0
fi

FILE=$(echo "$PICK" | cut -d: -f1)
LINE=$(echo "$PICK" | cut -d: -f2)
COL=$(echo "$PICK" | cut -d: -f3)

# Expand ~ if fzf returned it (though it shouldn't if SEARCH_DIRS are absolute)
FILE="${FILE/#\~/$HOME}"

# Open the selection in a NEW terminal/nvim (or you could use niri msg to focus an existing window)
wezterm start -- nvim "$FILE" "+call cursor($LINE, $COL)"
