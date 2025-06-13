#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up COSMIC Desktop Environment"

log "Installing COSMIC desktop environment from official Fedora groups"

# Install the main COSMIC desktop group
log "Installing COSMIC desktop group"
dnf5 group install --setopt=install_weak_deps=False --nogpgcheck -y "cosmic-desktop"

# Install COSMIC applications group  
log "Installing COSMIC desktop apps group"
dnf5 group install --setopt=install_weak_deps=False --nogpgcheck -y "cosmic-desktop-apps"

log "Setting up COSMIC system configuration"

# Create GSettings overrides for COSMIC with SoltrOS theming
mkdir -p /usr/share/glib-2.0/schemas

# Compile schemas
glib-compile-schemas /usr/share/glib-2.0/schemas/

# Remove Firefox to replace with Waterfox
log "Removing Firefox in favor of Waterfox"
dnf5 remove -y firefox firefox-* || true

log "Enabling COSMIC-related services"
# Enable services that COSMIC might need
systemctl enable pipewire.service || true
systemctl enable pipewire-pulse.service || true
systemctl enable wireplumber.service || true

log "COSMIC desktop environment setup complete"
log "Users can select 'COSMIC' from the login screen after installation"
log "Note: COSMIC is a Wayland-only desktop environment"