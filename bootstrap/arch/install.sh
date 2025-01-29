#!/bin/bash

# update the system and install base-devel
echo "Updating the system and installing base-devel and stow symlinker..."
sudo pacman -Syu --noconfirm
sudo pacman -S base-devel --noconfirm
sudo pacman -S stow --noconfirm

# install ansible
echo "Installing ansible..."
sudo pacman -S ansible --noconfirm

# verify ansible installation
echo "Verifying ansible installation..."
ansible --version
echo "Ansible installation complete."

# install yay
echo "Installing yay..."
sudo pacman -S --needed git base-devel --noconfirm
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
echo "yay installation complete."

# configure touchpad tapping
echo "Configuring touchpad for tap-to-click..."
sudo pacman -S xf86-input-libinput --noconfirm
sudo mkdir -p /etc/X11/xorg.conf.d/
echo 'Section "InputClass"
    Identifier "touchpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
    Option "ClickMethod" "clickfinger"
EndSection' | sudo tee /etc/X11/xorg.conf.d/40-libinput.conf >/dev/null

log_message "Installation completed successfully!"
