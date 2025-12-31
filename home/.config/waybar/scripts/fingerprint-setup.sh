#!/bin/bash

# Fingerprint Setup Script
# Provides easy fingerprint management with colored output

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if fprintd service is running
check_fprintd() {
    if ! systemctl is-active --quiet fprintd.service; then
        print_color $YELLOW "Starting fprintd service..."
        sudo systemctl start fprintd.service
        sleep 2
    fi
}

# Function to detect fingerprint device
detect_device() {
    local device=$(fprintd-list "$USER" 2>/dev/null | grep "found" | head -1)
    if [[ -z "$device" ]]; then
        print_color $RED "❌ No fingerprint device detected!"
        print_color $YELLOW "Make sure your fingerprint sensor is supported and drivers are installed."
        return 1
    fi
    print_color $GREEN "✅ Fingerprint device detected: $device"
    return 0
}

# Function to enroll fingerprint
enroll_fingerprint() {
    print_color $BLUE "󰈷 Starting fingerprint enrollment..."
    print_color $CYAN "Please follow the prompts to scan your finger multiple times."
    
    if fprintd-enroll; then
        print_color $GREEN "✅ Fingerprint enrolled successfully!"
        print_color $CYAN "You can now use your fingerprint for:"
        print_color $CYAN "  • Screen unlock (swaylock)"
        print_color $CYAN "  • Sudo authentication"
        print_color $CYAN "  • System prompts"
        print_color $CYAN "  • Login screen"
        print_color $YELLOW "💡 Tip: Press Ctrl+C during fingerprint prompt to use password instead"
    else
        print_color $RED "❌ Fingerprint enrollment failed!"
        return 1
    fi
}

# Function to remove fingerprint data
remove_fingerprint() {
    print_color $YELLOW "🗑️  Removing fingerprint data..."
    
    if fprintd-delete "$USER"; then
        print_color $GREEN "✅ Fingerprint data removed successfully!"
    else
        print_color $RED "❌ Failed to remove fingerprint data!"
        return 1
    fi
}

# Function to list enrolled fingerprints
list_fingerprints() {
    print_color $BLUE "📋 Enrolled fingerprints:"
    fprintd-list "$USER" 2>/dev/null || print_color $YELLOW "No fingerprints enrolled for user $USER"
}

# Function to test fingerprint verification
test_fingerprint() {
    print_color $BLUE "🧪 Testing fingerprint verification..."
    print_color $CYAN "Place your enrolled finger on the sensor..."
    
    if fprintd-verify; then
        print_color $GREEN "✅ Fingerprint verification successful!"
    else
        print_color $RED "❌ Fingerprint verification failed!"
        print_color $YELLOW "Make sure you're using an enrolled finger."
    fi
}

# Function to show help
show_help() {
    print_color $PURPLE "󰈷 Fingerprint Setup"
    echo
    print_color $CYAN "Usage: $0 [COMMAND]"
    echo
    print_color $YELLOW "Commands:"
    print_color $GREEN "  setup     Enroll fingerprint and enable authentication"
    print_color $RED "  remove    Remove fingerprint data"
    print_color $BLUE "  list      Show enrolled fingerprints"
    print_color $CYAN "  test      Test fingerprint verification"
    print_color $PURPLE "  help      Show this help message"
    echo
    print_color $YELLOW "Examples:"
    print_color $CYAN "  $0 setup    # Enroll your fingerprint"
    print_color $CYAN "  $0 test     # Test if fingerprint works"
    print_color $CYAN "  $0 remove   # Remove fingerprint data"
    echo
    print_color $YELLOW "Authentication works for:"
    print_color $CYAN "  • Screen unlock (Super+Escape → swaylock)"
    print_color $CYAN "  • Sudo commands"
    print_color $CYAN "  • System authentication prompts"
    print_color $CYAN "  • Login screen"
}

# Main script logic
main() {
    # Check if fprintd tools are available
    if ! command -v fprintd-enroll &> /dev/null; then
        print_color $RED "❌ fprintd tools not found!"
        print_color $YELLOW "Make sure fprintd is installed and configured."
        exit 1
    fi
    
    # Start fprintd service if needed
    check_fprintd
    
    # Handle command line arguments
    case "${1:-help}" in
        "setup")
            print_color $PURPLE "󰈷 Fingerprint Setup"
            echo
            if detect_device; then
                enroll_fingerprint
            fi
            ;;
        "remove")
            print_color $PURPLE "🗑️  Fingerprint Removal"
            echo
            remove_fingerprint
            ;;
        "list")
            print_color $PURPLE "📋 Fingerprint List"
            echo
            list_fingerprints
            ;;
        "test")
            print_color $PURPLE "🧪 Fingerprint Test"
            echo
            if detect_device; then
                test_fingerprint
            fi
        ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_color $RED "❌ Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
