#!/bin/bash
#
# ai-allow-dir.sh
#
# Grants the 'ai-agent' group access to a directory using ACLs.
# New files and folders automatically inherit the same permissions.
# Also grants traverse (execute) permission on parent directories.
#
# Usage: ./ai-allow-dir.sh /path/to/directory
#
# Note: macOS only. Uses chmod +a for ACL management.
#

set -e

GROUP_NAME="ai-agent"
USER_NAME="ai-agent"

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

# Check if directory argument provided
if [[ -z "$1" ]]; then
    error "Usage: $0 /path/to/directory"
fi

TARGET_DIR="$1"

# Resolve to absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || error "Directory does not exist: $1"

# Check if directory exists
if [[ ! -d "$TARGET_DIR" ]]; then
    error "Not a directory: $TARGET_DIR"
fi

# Check if group exists
if ! dscl . -read /Groups/"$GROUP_NAME" &>/dev/null; then
    error "Group '$GROUP_NAME' does not exist. Run create-ai-agent-user.sh first."
fi

# Grant traverse (execute) permission on parent directories
info "Granting traverse permission on parent directories..."
CURRENT="$TARGET_DIR"
while PARENT="$(dirname "$CURRENT")" && [[ "$PARENT" != "/" && "$PARENT" != "$CURRENT" ]]; do
    # Check if directory is already world-executable (o+x)
    if [[ -x "$PARENT" ]] && stat -f "%Sp" "$PARENT" | grep -q '..x$'; then
        info "  $PARENT (world-executable, skipping)"
    # Check if ai-agent already has execute permission via ACL
    elif ls -le "$PARENT" 2>/dev/null | grep -q "user:$USER_NAME allow.*execute"; then
        info "  $PARENT (already has traverse ACL)"
    else
        info "  $PARENT (adding traverse ACL)"
        chmod +a "user:$USER_NAME allow execute" "$PARENT"
    fi
    CURRENT="$PARENT"
done

info "Granting '$GROUP_NAME' group access to: $TARGET_DIR"

# Apply ACL recursively with inheritance
# - file_inherit: new files inherit this ACL
# - directory_inherit: new directories inherit this ACL
info "Applying ACL with inheritance..."
chmod -R +a "group:$GROUP_NAME allow read,write,execute,delete,append,readattr,writeattr,readextattr,writeextattr,readsecurity,list,search,add_file,add_subdirectory,delete_child,file_inherit,directory_inherit" "$TARGET_DIR"

echo ""
info "Done! Directory '$TARGET_DIR' is now accessible to the '$GROUP_NAME' group."
echo ""
echo "Verify with:"
echo "  ls -le \"$TARGET_DIR\""
echo ""
echo "Test access:"
echo "  sudo -u $USER_NAME ls \"$TARGET_DIR\""
echo "  sudo -u $USER_NAME touch \"$TARGET_DIR/test-file\" && rm \"$TARGET_DIR/test-file\""
