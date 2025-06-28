#!/bin/bash

set ${SET_X:+-x} -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing latest Waterfox browser"

# Get the latest Waterfox version from GitHub API
log "Fetching latest Waterfox version from GitHub API"
LATEST_VERSION=$(curl -s https://api.github.com/repos/BrowserWorks/Waterfox/releases/latest | grep '"tag_name"' | cut -d '"' -f 4)

if [ -z "$LATEST_VERSION" ]; then
    log "Error: Failed to fetch latest version from GitHub API, falling back to manual installation"
    exit 1
fi

log "Latest Waterfox version: $LATEST_VERSION"

# Construct download URL
WATERFOX_URL="https://cdn1.waterfox.net/waterfox/releases/${LATEST_VERSION}/Linux_x86_64/waterfox-${LATEST_VERSION}.tar.bz2"
ARCHIVE="/tmp/waterfox-${LATEST_VERSION}.tar.bz2"
INSTALL_DIR="/usr/share/soltros/waterfox"
BIN_LINK="/usr/share/soltros/waterfox/waterfox"
DESKTOP_FILE="/usr/share/applications/waterfox.desktop"

log "Downloading Waterfox ${LATEST_VERSION}"
curl --retry 3 --retry-delay 5 \
     --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
     -L -o "$ARCHIVE" \
     "$WATERFOX_URL"

# Check if download was successful
if [ ! -f "$ARCHIVE" ]; then
    log "Error: Failed to download Waterfox archive"
    exit 1
fi

log "Extracting Waterfox archive"
tar -xf "$ARCHIVE" -C "$INSTALL_DIR" --strip-components=1

log "Creating desktop launcher"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Waterfox
Comment=Privacy-focused web browser
Exec=$BIN_LINK %u
Icon=$INSTALL_DIR/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
StartupWMClass=Waterfox
EOF

chmod +x "$DESKTOP_FILE"

log "Cleaning up temporary files"
rm -f "$ARCHIVE"

log "Waterfox ${LATEST_VERSION} installation complete"
log "Installed to: $INSTALL_DIR"
log "Desktop file: $DESKTOP_FILE"
log "Command available: waterfox"
