#!/bin/bash
# Fast script to change ownership of files from ai-agent to executing user

# Use find with -exec + to batch files (faster than -exec \;)
# Run with sudo if needed for permission

# Use SUDO_USER if running via sudo, otherwise fall back to USER
TARGET_USER="${SUDO_USER:-$USER}"

DIR="${1-.}"

find "$DIR" -user ai-agent -exec chown "$TARGET_USER" {} +

echo "Done. Changed ownership of all ai-agent files in $DIR to $TARGET_USER."
