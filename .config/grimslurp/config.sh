# Screenshot directory
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"

# Screenshot filename format (using date)
SCREENSHOT_FILENAME="screenshot_%Y%m%d_%H%M%S.png"

# Notification settings
NOTIFY_TIMEOUT=5000  # milliseconds
NOTIFY_URGENCY="normal"

# Quality settings for PNG (0-100)
SCREENSHOT_QUALITY=100

# Create screenshots directory if it doesn't exist
mkdir -p "$SCREENSHOT_DIR"