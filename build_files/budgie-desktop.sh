#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up Budgie Desktop Environment"

log "Installing Budgie desktop environment from official Fedora groups"

# Install the main Budgie desktop group
log "Installing Budgie desktop group"
dnf5 group install --setopt=install_weak_deps=False --nogpgcheck -y "budgie-desktop"

# Install Budgie applications group  
log "Installing Budgie desktop apps group"
dnf5 group install --setopt=install_weak_deps=False --nogpgcheck -y "budgie-desktop-apps"

log "Setting up Budgie system configuration"

# Create GSettings overrides for Budgie with SoltrOS theming
mkdir -p /usr/share/glib-2.0/schemas

# Compile schemas
glib-compile-schemas /usr/share/glib-2.0/schemas/

# Remove Firefox to replace with Waterfox
log "Removing Firefox in favor of Waterfox"
dnf5 remove -y firefox firefox-* || true

log "Enabling Budgie-related services"
# Enable services that Budgie might need
systemctl enable pipewire.service || true
systemctl enable pipewire-pulse.service || true
systemctl enable wireplumber.service || true

log "Budgie desktop environment setup complete"
log "Users can select 'Budgie' from the login screen after installation"