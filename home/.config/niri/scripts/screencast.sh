#!/bin/bash

# Screen recording script for Niri with Audio Support and Recording Indicators
# Usage: screencast.sh [region|screen|region-audio|screen-audio|stop|toggle-screen|toggle-region]

RECORDING_DIR="$HOME/Videos/Recordings"
AUDIO_DIR="$HOME/Audio/Recordings"
PIDFILE="/tmp/wf-recorder.pid"
INDICATOR_FILE="/tmp/recording_indicator"
mkdir -p "$RECORDING_DIR"
mkdir -p "$AUDIO_DIR"

# Function to show recording indicator
show_recording_indicator() {
    local mode="$1"
    echo "$mode" >"$INDICATOR_FILE"
    # Send signal to waybar to update recording indicator
    pkill -RTMIN+8 waybar 2>/dev/null || true
    notify-send "󰑋 Recording" "Recording started ($mode)" -t 3000 -u normal
}

# Function to hide recording indicator
hide_recording_indicator() {
    local save_location="$1"
    rm -f "$INDICATOR_FILE"
    # Send signal to waybar to update recording indicator
    pkill -RTMIN+8 waybar 2>/dev/null || true
    notify-send "󰑊 Recording" "Recording stopped and saved to $save_location" -t 3000 -u normal
}

stop_recording() {
    if [ -f "$PIDFILE" ]; then
        local pid=$(cat "$PIDFILE")
        kill "$pid" 2>/dev/null
        rm -f "$PIDFILE"
        # Determine save location based on recording type
        if [ -f "$INDICATOR_FILE" ] && grep -q "Audio Only" "$INDICATOR_FILE"; then
            hide_recording_indicator "~/Audio/Recordings"
        else
            hide_recording_indicator "~/Videos/Recordings"
        fi
    else
        notify-send "Recording" "No recording in progress"
    fi
}

start_screen() {
    if [ -f "$PIDFILE" ]; then
        notify-send "Screen Recording" "Recording already in progress"
        return 1
    fi
    wf-recorder -f "$RECORDING_DIR/screencast-$(date +%Y%m%d-%H%M%S).mp4" &
    echo $! >"$PIDFILE"
    show_recording_indicator "Full Screen (No Audio)"
}

start_region() {
    if [ -f "$PIDFILE" ]; then
        notify-send "Screen Recording" "Recording already in progress"
        return 1
    fi
    GEOMETRY=$(slurp 2>/dev/null)
    if [ -n "$GEOMETRY" ]; then
        wf-recorder -g "$GEOMETRY" -f "$RECORDING_DIR/screencast-$(date +%Y%m%d-%H%M%S).mp4" &
        echo $! >"$PIDFILE"
        show_recording_indicator "Region (No Audio)"
    else
        notify-send "Screen Recording" "Region selection cancelled"
    fi
}

start_region_audio() {
    if [ -f "$PIDFILE" ]; then
        notify-send "Screen Recording" "Recording already in progress"
        return 1
    fi
    GEOMETRY=$(slurp 2>/dev/null)
    if [ -n "$GEOMETRY" ]; then
        wf-recorder -g "$GEOMETRY" --audio -f "$RECORDING_DIR/screencast-$(date +%Y%m%d-%H%M%S).mp4" &
        echo $! >"$PIDFILE"
        show_recording_indicator "Region + Audio"
    else
        notify-send "Screen Recording" "Region selection cancelled"
    fi
}

start_screen_audio() {
    if [ -f "$PIDFILE" ]; then
        notify-send "Screen Recording" "Recording already in progress"
        return 1
    fi
    wf-recorder --audio -f "$RECORDING_DIR/screencast-$(date +%Y%m%d-%H%M%S).mp4" &
    echo $! >"$PIDFILE"
    show_recording_indicator "Full Screen + Audio"
}

start_audio_only() {
    if [ -f "$PIDFILE" ]; then
        notify-send "Audio Recording" "Recording already in progress"
        return 1
    fi
    ffmpeg -f pulse -i default -c:a libmp3lame -b:a 128k "$AUDIO_DIR/audio-$(date +%Y%m%d-%H%M%S).mp3" &
    echo $! >"$PIDFILE"
    show_recording_indicator "Audio Only"
}

case "${1:-region}" in
    "region") start_region ;;
    "screen") start_screen ;;
    "region-audio") start_region_audio ;;
    "screen-audio") start_screen_audio ;;
    "audio-only") start_audio_only ;;
    "toggle-screen")
        if [ -f "$PIDFILE" ]; then
            stop_recording
        else
            start_screen
        fi
        ;;
    "toggle-region")
        if [ -f "$PIDFILE" ]; then
            stop_recording
        else
            start_region
        fi
        ;;
    "toggle-screen-audio")
        if [ -f "$PIDFILE" ]; then
            stop_recording
        else
            start_screen_audio
        fi
        ;;
    "toggle-region-audio")
        if [ -f "$PIDFILE" ]; then
            stop_recording
        else
            start_region_audio
        fi
        ;;
    "toggle-audio-only")
        if [ -f "$PIDFILE" ]; then
            stop_recording
        else
            start_audio_only
        fi
        ;;
    "stop") stop_recording ;;
    *)
        echo "Usage: $0 [region|screen|region-audio|screen-audio|audio-only|stop|toggle-screen|toggle-region]"
        exit 1
        ;;
esac
