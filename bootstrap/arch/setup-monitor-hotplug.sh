#!/bin/bash

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        echo "Please run as root"
        exit 1
    fi
}

# Setup monitor hotplug
setup_monitor_hotplug() {
    # Copy udev rule
    cp ../../etc/udev/rules.d/95-monitor-hotplug.rules /etc/udev/rules.d/
    chmod 644 /etc/udev/rules.d/95-monitor-hotplug.rules

    # Create sudoers file
    cat > /etc/sudoers.d/monitor-hotplug << 'EOF'
ALL ALL=(ALL) NOPASSWD: /home/*/\.config/scripts/monitor-hotplug.sh
EOF
    chmod 440 /etc/sudoers.d/monitor-hotplug

    # Reload udev rules
    udevadm control --reload-rules
    echo "Monitor hotplug setup completed"
}

# Main
check_root
setup_monitor_hotplug
