#!/bin/bash
#
# ai-shell.sh
#
# Opens an interactive login shell as the 'ai-agent' user.
#
# Usage: ./ai-shell.sh
#

USER_NAME="ai-agent"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

passwordless_sudo_tip() {
    local invoking_user="${SUDO_USER:-$USER}"
    echo -e "${YELLOW}[TIP]${NC} To avoid password prompts, run: sudo visudo -f /etc/sudoers.d/ai-agent"
    echo -e "      and add: ${invoking_user} ALL=(root) NOPASSWD: /usr/bin/su - ${USER_NAME}, /usr/bin/su - ${USER_NAME} -c *"
    echo ""
}

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    error "This script only supports macOS"
fi

# Check if ai-agent user exists
if ! dscl . -read /Users/"$USER_NAME" &>/dev/null; then
    error "User '$USER_NAME' does not exist. Run create-ai-agent-user.sh first."
fi

# Show tip about passwordless sudo (only if not already configured)
if ! sudo -n su - "$USER_NAME" -c true 2>/dev/null; then
    passwordless_sudo_tip
fi

# start a new login shell ("-" arg), but use the PATH of the outer user
exec sudo su - "$USER_NAME" -c "export PATH='$PATH'; exec \$SHELL -l"
