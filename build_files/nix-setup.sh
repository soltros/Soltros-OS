#!/usr/bin/bash
# SoltrOS: Nix Package Manager Setup Script
# Installs Nix package manager for additional package management

set ${SET_X:+-x} -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing Nix package manager"

# Check if Nix is already installed
if [ -d "/nix" ] && [ -f "/nix/var/nix/profiles/default/bin/nix" ]; then
    log "Nix is already installed, skipping installation"
    exit 0
fi

# Check if nixbld group exists and get its info
if getent group nixbld >/dev/null 2>&1; then
    NIXBLD_GID=$(getent group nixbld | cut -d: -f3)
    log "Found existing nixbld group with GID $NIXBLD_GID"

    # Check if nixbld users exist and get first UID
    if id "nixbld1" >/dev/null 2>&1; then
        FIRST_UID=$(id -u "nixbld1")
        log "Found existing nixbld users starting with UID $FIRST_UID"
        USERS_EXIST=true
    else
        USERS_EXIST=false
    fi
else
    log "No existing nixbld group found"
    USERS_EXIST=false
fi

# Create necessary directories
mkdir -p /nix
mkdir -p /etc/nix
mkdir -p /root  # Ensure root directory exists for the installer

# Download and install Nix using the official installer with proper environment variables
NIX_VERSION="2.24.10"
log "Downloading Nix $NIX_VERSION"
curl -L https://releases.nixos.org/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}-x86_64-linux.tar.xz | tar -xJ

# Install Nix with appropriate environment variables
cd nix-${NIX_VERSION}-x86_64-linux

if [ "$USERS_EXIST" = true ]; then
    log "Installing Nix with existing users (GID: $NIXBLD_GID, First UID: $FIRST_UID)"
    env NIX_BUILD_GROUP_ID=$NIXBLD_GID NIX_FIRST_BUILD_UID=$FIRST_UID ./install --daemon --yes --no-channel-add
else
    log "Installing Nix with default settings"
    ./install --daemon --yes --no-channel-add
fi

# Clean up installer
cd ..
rm -rf nix-${NIX_VERSION}-x86_64-linux

log "Configuring Nix for multi-user setup"

# Create nix configuration
cat > /etc/nix/nix.conf << 'EOF'
# SoltrOS Nix Configuration
build-users-group = nixbld
experimental-features = nix-command flakes
auto-optimise-store = true
trusted-users = root @wheel
EOF

# Setup Nix profile scripts
mkdir -p /etc/profile.d

cat > /etc/profile.d/nix.sh << 'EOF'
# Nix package manager setup
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
EOF

# Setup Nix for Fish shell
mkdir -p /etc/fish/conf.d
cat > /etc/fish/conf.d/nix.fish << 'EOF'
# Nix package manager setup for Fish
if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    bass source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
end
EOF

# The Nix installer should have created systemd services, but let's ensure they're enabled
if [ -f "/etc/systemd/system/nix-daemon.service" ]; then
    systemctl enable nix-daemon.service
fi

if [ -f "/etc/systemd/system/nix-daemon.socket" ]; then
    systemctl enable nix-daemon.socket
fi

# Set proper permissions if needed
if [ -d "/nix" ]; then
    chown -R root:nixbld /nix 2>/dev/null || true
    chmod 1775 /nix/store 2>/dev/null || true
fi

log "Setting up Nix channels"

# Manually setup channels since we skipped it during installation
if [ -f "/nix/var/nix/profiles/default/bin/nix-channel" ]; then
    # Create the channels file manually
    echo "https://nixos.org/channels/nixpkgs-unstable nixpkgs" > /root/.nix-channels
    /nix/var/nix/profiles/default/bin/nix-channel --update || log "Warning: Channel update failed, users can run this later"
else
    log "Warning: nix-channel not found, channels will need to be set up by users"
fi

log "Nix package manager installation completed"
