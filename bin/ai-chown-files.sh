#!/bin/bash
#
# ai-chown-files.sh
#
# Changes ownership of files from ai-agent to the current user.
# Uses sudo internally — no need to invoke this script with sudo.
#
# Usage: ./ai-chown-files.sh [directory]
#
# If no directory is specified, uses the current directory.
#

set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "$0")" && /bin/pwd)/$(basename "$0")"

# Colors for output
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

passwordless_sudo_tip() {
    local invoking_user="${SUDO_USER:-$USER}"
    echo -e "${YELLOW}[TIP]${NC} To avoid password prompts, run: sudo visudo -f /etc/sudoers.d/ai-agent"
    echo -e "      and add: ${invoking_user} ALL=(root) NOPASSWD: ${SCRIPT_PATH}, ${SCRIPT_PATH} *"
    echo ""
}

# Self-elevate to root if needed
if [ "$(/usr/bin/id -u)" -ne 0 ]; then
    if ! sudo -n true 2>/dev/null; then
        passwordless_sudo_tip
    fi
    exec sudo "$SCRIPT_PATH" "$@"
fi

# --- Running as root via sudo ---
TARGET_USER="${SUDO_USER:?This script must be run via sudo}"
DIR="${1:-.}"

/usr/bin/find "$DIR" -user ai-agent -exec /usr/sbin/chown "$TARGET_USER" {} +

echo "Done. Changed ownership of all ai-agent files in $DIR to $TARGET_USER."
