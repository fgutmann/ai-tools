#!/bin/bash
#
# ai-pi.sh
#
# Runs the pi coding agent as the 'ai-agent' user with restricted permissions.
#
# Usage: ./ai-pi.sh [directory] [pi-args...]
#
# If no directory is specified, uses the current directory.
# The directory must be accessible to the ai-agent user (use ai-allow-dir.sh first).
#
# Examples:
#   ./ai-pi.sh                           # Run in current directory
#   ./ai-pi.sh /path/to/project          # Run in specific directory
#   ./ai-pi.sh . --model sonnet          # Pass arguments to pi
#

USER_NAME="ai-agent"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    error "This script only supports macOS"
fi

# Check if ai-agent user exists
if ! dscl . -read /Users/"$USER_NAME" &>/dev/null; then
    error "User '$USER_NAME' does not exist. Run create-ai-agent-user.sh first."
fi

# Determine working directory
if [[ -n "$1" && -d "$1" ]]; then
    WORK_DIR="$(cd "$1" && pwd)"
    shift
else
    WORK_DIR="$(pwd)"
fi

# Remaining arguments are passed to pi
PI_ARGS=("$@")

# Run pi as ai-agent
# Show tip about passwordless sudo (only if not already configured)
if ! sudo -n -u "$USER_NAME" true 2>/dev/null; then
    echo -e "${YELLOW}[TIP]${NC} To avoid password prompts, run: sudo visudo -f /etc/sudoers.d/ai-agent"
    echo -e "      and add: ${SUDO_USER:-$USER} ALL=($USER_NAME) NOPASSWD: ALL"
    echo ""
fi

# Check if ai-agent can access the directory
if ! sudo -u "$USER_NAME" test -r "$WORK_DIR" 2>/dev/null; then
    error "Directory '$WORK_DIR' is not accessible to '$USER_NAME'. Run: ./ai-allow-dir.sh \"$WORK_DIR\""
fi

exec sudo -u "$USER_NAME" -i bash -c "cd '$WORK_DIR' && pi ${PI_ARGS[*]}"
