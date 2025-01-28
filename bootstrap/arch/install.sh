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

# Create udev rule
log_message "Creating udev rule for monitor hotplug..."
sudo mkdir -p /etc/udev/rules.d/
cat <<EOF | sudo tee /etc/udev/rules.d/95-monitor-hotplug.rules >/dev/null
ACTION=="change", SUBSYSTEM=="drm", RUN+="/bin/bash -c 'export DISPLAY=:0; export XAUTHORITY=/home/$USER/.Xauthority; /home/$USER/.config/scripts/monitor-setup.sh'"
EOF
check_status "udev rule creation"

# Reload udev rules
log_message "Reloading udev rules..."
sudo udevadm control --reload-rules
check_status "udev rules reload"

log_message "Installation completed successfully!"
