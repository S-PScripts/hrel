#!/bin/bash

set -e

# === CONFIGURABLE VARIABLES ===
HYDROGEN_M_URL="https://github.com/xgladius/hrel/raw/refs/heads/main/Hydrogen-M.zip"
TMP_DIR="/tmp/hydrogen_m_install"
HYDROGEN_APP_PATH="/Applications/Hydrogen-M.app"
ROBLOX_PATH="/Applications/Roblox.app/Contents/MacOS"
ROBLOX_PLAYER="$ROBLOX_PATH/RobloxPlayer"
ROBLOX_PLAYER_COPY="$ROBLOX_PATH/RobloxPlayer.copy"

# === FUNCTIONS ===

error_exit() {
    echo "Error: $1"
    exit 1
}

info() {
    echo "[*] $1"
}

success() {
    echo "[✔] $1"
}

# === CHECKS ===

# 1. Check for existence of RobloxPlayer
if [ ! -f "$ROBLOX_PLAYER" ]; then
    error_exit "RobloxPlayer not found at $ROBLOX_PLAYER. Please install Roblox first."
fi

# 2. Check architecture
# SYSTEM_ARCH=$(uname -m)
# BINARY_ARCH=$(file "$ROBLOX_PLAYER" | grep -o 'arm64' || true)

# if [ "$SYSTEM_ARCH" != "arm64" ]; then
#     error_exit "Hydrogen-M does not support Intel Macs. This system is $SYSTEM_ARCH."
# fi

# if [ "$BINARY_ARCH" != "arm64" ]; then
#     error_exit "RobloxPlayer is not an arm64 binary. Hydrogen-M requires arm64 builds."
# fi

# info "System and RobloxPlayer architecture are compatible (arm64)."

# 3. Download Hydrogen-M app
info "Downloading Hydrogen-M from $HYDROGEN_M_URL..."
mkdir -p "$TMP_DIR"
curl -L "$HYDROGEN_M_URL" -o "$TMP_DIR/Hydrogen-M.zip"
unzip -oq "$TMP_DIR/Hydrogen-M.zip" -d "$TMP_DIR"

info "Moving Hydrogen-M to /Applications..."
rm -rf "$HYDROGEN_APP_PATH"
mv "$TMP_DIR/Hydrogen-M.app" "$HYDROGEN_APP_PATH"

# 4. RobloxPlayer copy handling
if [ ! -f "$ROBLOX_PLAYER_COPY" ]; then
    info "Creating RobloxPlayer.copy..."
    cp "$ROBLOX_PLAYER" "$ROBLOX_PLAYER_COPY"
else
    info "Restoring original RobloxPlayer from copy..."
    rm -f "$ROBLOX_PLAYER"
    mv "$ROBLOX_PLAYER_COPY" "$ROBLOX_PLAYER"
fi

# 5. Inject dylib
info "Injecting Hydrogen-M dylib into RobloxPlayer..."
"$HYDROGEN_APP_PATH/Contents/MacOS/insert_dylib" \
    "$HYDROGEN_APP_PATH/Contents/MacOS/hydrogen-m.dylib" \
    "$ROBLOX_PLAYER_COPY" "$ROBLOX_PLAYER" --all-yes

# 6. Resign Roblox app
info "Codesigning Roblox..."
codesign --force --deep --sign - "/Applications/Roblox.app"

# 7. Finish
success "Hydrogen-M installed successfully!"
echo "Enjoy the experience! Please provide feedback to help us improve."
