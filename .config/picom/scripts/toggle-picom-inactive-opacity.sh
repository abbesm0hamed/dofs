#!/bin/bash

# Get user home directory
USER_HOME=$(getent passwd $USER | cut -d: -f6)

# Data.
NO_DIM="inactive-opacity = 1.00;"
DIM="inactive-opacity = 0.95;"
FILENAME="$USER_HOME/.config/picom/picom.conf"
STATE_FILE="$USER_HOME/.config/picom/read-mode-state"

# Clear the file contents.
>$STATE_FILE

# Check dim state.
if grep -Fxq "$DIM" $FILENAME; then # Currently dim.
  sed -i "s/$DIM/$NO_DIM/g" $FILENAME
  echo ' On' >>$STATE_FILE
# Currently no dim.
else
  sed -i "s/$NO_DIM/$DIM/g" $FILENAME
  echo 'Off' >>$STATE_FILE
fi
