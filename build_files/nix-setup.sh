#!/usr/bin/bash
# SoltrOS: Nix Package Manager Setup Script
# Installs Nix package manager using Determinate Systems installer

set ${SET_X:+-x} -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing Nix package manager using Determinate Systems installer"

# Check if Nix is already installed
if [ -d "/nix" ] && [ -f "/nix/var/nix/profiles/default/bin/nix" ]; then
    log "Nix is already installed, skipping installation"
    exit 0
fi

# Install Nix using Determinate Systems installer (perfect for containers)
log "Installing Nix with container-optimized settings"
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux \
    --no-confirm \
    --init none \
    --extra-conf "sandbox = false" \
    --extra-conf "experimental-features = nix-command flakes" \
    --extra-conf "auto-optimise-store = true" \
    --extra-conf "trusted-users = root @wheel"

log "Nix installation completed successfully"

# Setup Nix profile scripts for SoltrOS integration
log "Setting up SoltrOS Nix integration"

# Setup Nix for Fish shell (since SoltrOS uses Fish)
mkdir -p /etc/fish/conf.d
cat > /etc/fish/conf.d/nix.fish << 'EOF'
# Nix package manager setup for Fish
if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    bass source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
end
EOF

# Ensure the Nix daemon will start on boot
if [ -f "/etc/systemd/system/nix-daemon.service" ]; then
    systemctl enable nix-daemon.service
    log "Enabled nix-daemon.service"
fi

if [ -f "/etc/systemd/system/nix-daemon.socket" ]; then
    systemctl enable nix-daemon.socket
    log "Enabled nix-daemon.socket"
fi

# Add PATH to profile for shell integration
mkdir -p /etc/profile.d
cat > /etc/profile.d/nix.sh << 'EOF'
# Nix package manager setup
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
EOF

# Set proper permissions
if [ -d "/nix" ]; then
    chown -R root:nixbld /nix 2>/dev/null || true
    chmod 1775 /nix/store 2>/dev/null || true
fi

log "SoltrOS Nix package manager setup completed successfully"
log "Users can run 'just nix-setup-user' to configure Nix for their account"
