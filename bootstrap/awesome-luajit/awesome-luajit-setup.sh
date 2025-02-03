#!/bin/bash

set -e  # Exit on any error

# Function to check for required commands
check_command() {
  if ! command -v "$1" &>/dev/null; then
    echo "Error: $1 is not installed." >&2
    exit 1
  fi
}

# Check for git and base-devel
check_command "git"
check_command "make"

# Detect AUR helper
if command -v yay &>/dev/null; then
  AUR_HELPER="yay"
elif command -v paru &>/dev/null; then
  AUR_HELPER="paru"\else
  echo "No AUR helper detected. Proceeding with manual installation."
  AUR_HELPER=""
fi

# Remove conflicting packages first
remove_conflicts() {
  local pkg=$1
  if pacman -Qi lua51-lgi &>/dev/null; then
    echo "Removing conflicting package lua51-lgi..."
    sudo pacman -R --noconfirm lua51-lgi
  fi
}

PACKAGE="awesome-luajit-git"

if [[ -n $AUR_HELPER ]]; then
  echo "Using $AUR_HELPER to install $PACKAGE."
  remove_conflicts $PACKAGE
  $AUR_HELPER -S --noconfirm --needed $PACKAGE
else
  echo "Manually cloning and building $PACKAGE."

  # Create a temporary directory for the build
  TEMP_DIR=$(mktemp -d)
  echo "Cloning into $TEMP_DIR."

  git clone https://aur.archlinux.org/$PACKAGE.git "$TEMP_DIR"
  cd "$TEMP_DIR"

  echo "Building and installing $PACKAGE."
  makepkg -si --noconfirm

  # Clean up
  cd -
  rm -rf "$TEMP_DIR"
fi

echo "$PACKAGE installation complete."
