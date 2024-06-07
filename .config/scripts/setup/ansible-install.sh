#!/bin/bash

# Update the system and install base-devel
echo "Updating the system and installing base-devel..."
sudo pacman -Syu --noconfirm
sudo pacman -S base-devel --noconfirm

# Install Ansible
echo "Installing Ansible..."
sudo pacman -S ansible --noconfirm

# Verify Ansible installation
echo "Verifying Ansible installation..."
ansible --version

echo "Ansible installation complete."
