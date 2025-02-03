#!/bin/bash

# Function to check if a package is installed
is_installed() {
    pacman -Qi "$1" &> /dev/null
    return $?
}

# Install required packages if not present
echo "Installing required packages..."
PACKAGES=(autorandr feh xorg-xrandr)
for package in "${PACKAGES[@]}"; do
    if ! is_installed "$package"; then
        echo "Installing $package..."
        sudo pacman -S --noconfirm "$package"
    fi
done

# Create necessary directories
echo "Creating configuration directories..."
mkdir -p ~/.config/autorandr/default
mkdir -p ~/.config/systemd/user
mkdir -p ~/.config/autorandr

# Copy udev rules
echo "Setting up udev rules..."
sudo mkdir -p /etc/udev/rules.d
sudo cp ~/dofs/bootstrap/system-config/udev/rules.d/95-monitor-hotplug.rules /etc/udev/rules.d/
sudo udevadm control --reload

# Enable and start systemd services
echo "Setting up systemd services..."
systemctl --user daemon-reload
systemctl --user enable autorandr.service
systemctl --user enable autorandr-monitor.path
systemctl --user start autorandr-monitor.path

# Generate initial monitor configuration
echo "Generating initial monitor configuration..."
autorandr --save default

# Make postswitch script executable
echo "Setting up autorandr hooks..."
chmod +x ~/.config/autorandr/postswitch.sh

# Initial wallpaper setup
echo "Setting up initial wallpapers..."
~/.config/autorandr/postswitch.sh

echo "Monitor setup complete! Your system is now configured to handle monitor changes automatically."
