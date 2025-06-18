#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up cinnamon Desktop Environment"

log "Installing cinnamon desktop environment from official Fedora groups"

# Install the main cinnamon desktop group
log "Installing cinnamon desktop group"
dnf5 group install --nogpgcheck -y "cinnamon-desktop"

# Install cinnamon applications group  
log "Installing cinnamon desktop apps group"
dnf5 group install --nogpgcheck -y "cinnamon-desktop-apps"

log "Setting up cinnamon system configuration"

# Create GSettings overrides for cinnamon with SoltrOS theming
mkdir -p /usr/share/glib-2.0/schemas

# Compile schemas
glib-compile-schemas /usr/share/glib-2.0/schemas/

# Remove Firefox to replace with Waterfox
log "Removing Firefox in favor of Waterfox"
dnf5 remove -y firefox firefox-* || true

log "Enabling cinnamon-related services"
# Enable services that cinnamon might need
systemctl enable pipewire.service || true
systemctl enable pipewire-pulse.service || true
systemctl enable wireplumber.service || true

log "cinnamon desktop environment setup complete"
log "Users can select 'cinnamon' from the login screen after installation"