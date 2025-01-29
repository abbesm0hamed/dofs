#!/bin/bash

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check command status
check_status() {
    if [ $? -eq 0 ]; then
        log_message "$1 completed successfully"
    else
        log_message "ERROR: $1 failed"
        exit 1
    fi
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_message "Please run as root"
        exit 1
    fi
}

# Function to setup monitor hotplug
setup_monitor_hotplug() {
    # Create udev rules directory if it doesn't exist
    log_message "Creating udev rule for monitor hotplug..."
    mkdir -p /etc/udev/rules.d/

    # Create udev rule with proper permissions
    cat <<EOF >/etc/udev/rules.d/95-monitor-hotplug.rules
ACTION=="change", SUBSYSTEM=="drm", RUN+="/bin/bash -c 'export DISPLAY=:0; export XAUTHORITY=/home/\$USER/.Xauthority; /home/\$USER/.config/scripts/monitor-setup.sh'"
ACTION=="change", SUBSYSTEM=="drm", RUN+="/bin/bash -c 'export DISPLAY=:0; export XAUTHORITY=/home/\$USER/.Xauthority; /home/\$USER/.config/scripts/setup-wallpaper.sh'"
EOF
    chmod 644 /etc/udev/rules.d/95-monitor-hotplug.rules
    check_status "udev rule creation"

    # Create sudoers file for script execution
    log_message "Setting up sudo permissions..."
    cat >/etc/sudoers.d/monitor-hotplug <<'EOF'
ALL ALL=(ALL) NOPASSWD: /home/*/.config/scripts/monitor-setup.sh
ALL ALL=(ALL) NOPASSWD: /home/*/.config/scripts/setup_wallpaper.sh
EOF
    chmod 440 /etc/sudoers.d/monitor-hotplug
    check_status "sudoers configuration"

    # Reload udev rules
    log_message "Reloading udev rules..."
    udevadm control --reload-rules
    check_status "udev rules reload"

    log_message "Monitor hotplug setup completed successfully"
}

# Main execution
check_root
setup_monitor_hotplug
