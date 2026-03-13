#!/usr/bin/env bash
set -euo pipefail

# NOTE: displayplacer is not available in nixpkgs, only via Homebrew
# To install manually: brew install displayplacer

# Check if displayplacer is installed, if not install via brew
if ! command -v displayplacer &> /dev/null; then
    echo "displayplacer not found. Installing via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "Error: Homebrew is not installed. Please install Homebrew first."
        echo "Visit: https://brew.sh"
        exit 1
    fi
    brew install displayplacer
fi

# Check yabai and skhd service status
echo "Checking yabai and skhd services..."
YABAI_WAS_RUNNING=false
SKHD_WAS_RUNNING=false

if launchctl list org.nixos.yabai &>/dev/null; then
    YABAI_WAS_RUNNING=true
    echo "Stopping yabai service..."
    launchctl bootout gui/$(id -u)/org.nixos.yabai
fi

if launchctl list org.nixos.skhd &>/dev/null; then
    SKHD_WAS_RUNNING=true
    echo "Stopping skhd service..."
    launchctl bootout gui/$(id -u)/org.nixos.skhd
fi

# Store current display configuration
echo "Storing current display configuration..."
# Capture the full output to analyze display count
DISPLAY_INFO=$(displayplacer list)
# Capture the last line that starts with "displayplacer" which contains the restore command
ORIGINAL_CONFIG=$(echo "$DISPLAY_INFO" | grep "^displayplacer" | tail -1)

# Count number of displays
DISPLAY_COUNT=$(echo "$DISPLAY_INFO" | grep -c "Persistent screen id:")
echo "Detected $DISPLAY_COUNT display(s)"

# Save to a temporary file for safety
TEMP_CONFIG=$(mktemp)
echo "$ORIGINAL_CONFIG" > "$TEMP_CONFIG"

# Store whether we're in multiple display mode and identify monitors
IS_MULTIPLE_DISPLAYS=false
EXTERNAL_MONITOR_ID=""
MACBOOK_MONITOR_ID=""

if [ "$DISPLAY_COUNT" -gt 1 ]; then
    IS_MULTIPLE_DISPLAYS=true
    echo "Multiple displays detected."

    # Extract external monitor ID (type: external screen)
    EXTERNAL_MONITOR_ID=$(echo "$DISPLAY_INFO" | grep -B 3 "external screen" | grep "Persistent screen id:" | awk '{print $NF}')

    # Extract MacBook monitor ID (type: MacBook built in screen)
    MACBOOK_MONITOR_ID=$(echo "$DISPLAY_INFO" | grep -B 3 "MacBook built in screen" | grep "Persistent screen id:" | awk '{print $NF}')

    if [ -n "$EXTERNAL_MONITOR_ID" ] && [ -n "$MACBOOK_MONITOR_ID" ]; then
        echo "Found external monitor: $EXTERNAL_MONITOR_ID"
        echo "Found MacBook monitor: $MACBOOK_MONITOR_ID"
        echo "Will switch external monitor to mirror MacBook display."
    else
        echo "Warning: Could not identify external and MacBook monitors."
        IS_MULTIPLE_DISPLAYS=false
    fi
fi

# Function to restore everything on exit
cleanup() {
    echo "Restoring original display configuration..."
    if [ -f "$TEMP_CONFIG" ]; then
        bash -c "$(cat "$TEMP_CONFIG")"
        rm -f "$TEMP_CONFIG"
    fi

    # Restore yabai if it was running
    if [ "$YABAI_WAS_RUNNING" = true ]; then
        echo "Starting yabai service..."
        launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nixos.yabai.plist
    fi

    # Restore skhd if it was running
    if [ "$SKHD_WAS_RUNNING" = true ]; then
        echo "Starting skhd service..."
        launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.nixos.skhd.plist
    fi
}

# Set trap to restore everything on exit
trap cleanup EXIT INT TERM

# Switch to 1280x832 resolution
echo "Switching to 1280x832 resolution..."

if [ "$IS_MULTIPLE_DISPLAYS" = true ]; then
    # For multiple displays, enable mirror mode
    echo "Enabling mirror mode on external monitor..."

    # Use the proper mirror syntax: id:ID1+ID2 with 1280x832 resolution
    # This mirrors both displays at the same resolution
    displayplacer "id:$MACBOOK_MONITOR_ID+$EXTERNAL_MONITOR_ID res:1280x832 hz:60 color_depth:8 enabled:true scaling:on origin:(0,0) degree:0"
else
    # Single display: change to compatible resolution
    # Check if it's an external monitor (doesn't support 1280x832) or MacBook (does support it)
    DISPLAY_TYPE=$(echo "$DISPLAY_INFO" | grep "Type:")

    if echo "$DISPLAY_TYPE" | grep -q "external screen"; then
        # External monitor - use 1280x720 which is supported
        echo "External monitor detected, using 1280x720..."
        NEW_CONFIG=$(echo "$ORIGINAL_CONFIG" | sed -E 's/res:[0-9]+x[0-9]+/res:1280x720/')
    else
        # MacBook or other display that supports 1280x832
        echo "MacBook display detected, using 1280x832..."
        NEW_CONFIG=$(echo "$ORIGINAL_CONFIG" | sed -E 's/res:[0-9]+x[0-9]+/res:1280x832/')
    fi
    eval "$NEW_CONFIG"
fi

# Launch the game/application
echo "Launching Dota 2 via Steam..."
# Use 'open' command with steam:// URL protocol (works without steam in PATH)
# Dota 2 App ID is 570
open "steam://rungameid/570"

# Wait a moment for Steam to launch
sleep 2

# Optional: Wait for Dota 2 process to exist before monitoring
echo "Waiting for Dota 2 to start..."
while ! pgrep -x "dota2" > /dev/null; do
    sleep 1
done

echo "Dota 2 is running. Monitoring process..."
# Wait for Dota 2 to close
while pgrep -x "dota2" > /dev/null; do
    sleep 5
done

echo "Dota 2 has closed. Restoring resolution..."