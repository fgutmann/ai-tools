#!/bin/bash
#
# ai-chrome.sh
#
# Launches Google Chrome with an isolated profile for AI agent use.
# Keeps AI-accessible browsing separate from your personal Chrome.
#
# Usage: ./ai-chrome.sh [--debug]
#
# Options:
#   --debug    Enable remote debugging on port 9222
#

PROFILE_DIR="${HOME}/ai-chrome-profile"
CHROME_APP="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Create profile directory if it doesn't exist
mkdir -p "$PROFILE_DIR"

# Build arguments
ARGS=(--user-data-dir="$PROFILE_DIR")

# Check for debug flag
if [[ "$1" == "--debug" ]]; then
    ARGS+=(--remote-debugging-port=9222)
    echo "Remote debugging enabled on http://localhost:9222"
fi

echo "Launching Chrome with isolated profile: $PROFILE_DIR"
exec "$CHROME_APP" "${ARGS[@]}"
