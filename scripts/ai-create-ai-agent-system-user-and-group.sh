#!/bin/bash
#
# create-ai-agent-user.sh
#
# Creates a restricted 'ai-agent' user and group on macOS for running
# AI coding agents (like pi) with limited file system access.
#
# Usage: sudo ./create-ai-agent-user.sh
#
# Note: macOS only. Uses dscl for user/group management.
#

set -e

USER_NAME="ai-agent"
GROUP_NAME="ai-agent"
REAL_NAME="AI Agent"
SHELL="/bin/zsh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    error "This script only supports macOS"
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
fi

# Function to find the next available UID (starting from 501 for regular users)
find_next_uid() {
    local uid=501
    while dscl . -list /Users UniqueID | awk '{print $2}' | grep -q "^${uid}$"; do
        ((uid++))
    done
    echo "$uid"
}

# Function to find the next available GID (starting from 501)
find_next_gid() {
    local gid=501
    while dscl . -list /Groups PrimaryGroupID 2>/dev/null | awk '{print $2}' | grep -q "^${gid}$"; do
        ((gid++))
    done
    echo "$gid"
}

# Check if group already exists
if dscl . -read /Groups/"$GROUP_NAME" &>/dev/null; then
    warn "Group '$GROUP_NAME' already exists, skipping group creation"
else
    info "Creating group '$GROUP_NAME'..."
    
    GID=$(find_next_gid)
    info "Using GID: $GID"
    
    dscl . -create /Groups/"$GROUP_NAME"
    dscl . -create /Groups/"$GROUP_NAME" PrimaryGroupID "$GID"
    dscl . -create /Groups/"$GROUP_NAME" RealName "$REAL_NAME"
    
    info "Group '$GROUP_NAME' created successfully"
fi

# Check if user already exists
if dscl . -read /Users/"$USER_NAME" &>/dev/null; then
    warn "User '$USER_NAME' already exists, skipping user creation"
else
    info "Creating user '$USER_NAME'..."
    
    UID_NUM=$(find_next_uid)
    info "Using UID: $UID_NUM"
    
    # Get the GID of the group we created (or that already existed)
    GID=$(dscl . -read /Groups/"$GROUP_NAME" PrimaryGroupID | awk '{print $2}')
    
    dscl . -create /Users/"$USER_NAME"
    dscl . -create /Users/"$USER_NAME" UserShell "$SHELL"
    dscl . -create /Users/"$USER_NAME" RealName "$REAL_NAME"
    dscl . -create /Users/"$USER_NAME" UniqueID "$UID_NUM"
    dscl . -create /Users/"$USER_NAME" PrimaryGroupID "$GID"
    dscl . -create /Users/"$USER_NAME" NFSHomeDirectory /Users/"$USER_NAME"
    
    # Create home directory
    if [[ ! -d /Users/"$USER_NAME" ]]; then
        info "Creating home directory /Users/$USER_NAME..."
        mkdir -p /Users/"$USER_NAME"
        chown "$USER_NAME":"$GROUP_NAME" /Users/"$USER_NAME"
        chmod 750 /Users/"$USER_NAME"
    fi
    
    # Hide user from login screen (UID < 500 are hidden by default, but we can also hide explicitly)
    dscl . -create /Users/"$USER_NAME" IsHidden 1
    
    info "User '$USER_NAME' created successfully"
fi

# Add the user to the group (in case they weren't added automatically)
if ! dscl . -read /Groups/"$GROUP_NAME" GroupMembership 2>/dev/null | grep -q "$USER_NAME"; then
    info "Adding '$USER_NAME' to group '$GROUP_NAME'..."
    dscl . -append /Groups/"$GROUP_NAME" GroupMembership "$USER_NAME"
fi

# Get the current (calling) user
CALLING_USER="${SUDO_USER:-$USER}"
if [[ -n "$CALLING_USER" && "$CALLING_USER" != "root" ]]; then
    if ! dscl . -read /Groups/"$GROUP_NAME" GroupMembership 2>/dev/null | grep -q "$CALLING_USER"; then
        info "Adding '$CALLING_USER' to group '$GROUP_NAME'..."
        dscl . -append /Groups/"$GROUP_NAME" GroupMembership "$CALLING_USER"
        warn "You may need to log out and back in for group membership to take effect"
    else
        info "User '$CALLING_USER' is already a member of group '$GROUP_NAME'"
    fi
fi

echo ""
info "Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Grant access to specific directories:"
echo "     ./ai-allow-dir.sh /path/to/allowed/directory"
echo ""
echo "  2. Set up Node.js and pi for the $USER_NAME user:"
echo "     sudo su - $USER_NAME"
echo "     curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
echo "     Make sure nvm setup exists in your shell initialization file."
echo "     Then: nvm install 24 && npm install -g @mariozechner/pi-coding-agent"
echo ""
echo "  3. Run pi as the restricted user:"
echo "     sudo -u $USER_NAME -i bash -c 'cd /path/to/allowed/directory && pi'"
