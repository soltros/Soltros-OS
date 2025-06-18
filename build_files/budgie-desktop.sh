#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up budgie Desktop Environment"

log "Installing budgie desktop environment from official Fedora groups"

# Install the main budgie desktop group
log "Installing budgie desktop group"
dnf5 group install --nogpgcheck -y "budgie-desktop"

log "Installing budgie desktop applications group"
dnf5 group install --nogpgcheck -y "budgie-desktop-apps"

log "Setting up budgie system configuration"

# Create GSettings overrides for budgie with SoltrOS theming
mkdir -p /usr/share/glib-2.0/schemas

# Compile schemas
glib-compile-schemas /usr/share/glib-2.0/schemas/

# Remove Firefox to replace with Waterfox
log "Removing Firefox in favor of Waterfox"
dnf5 remove -y firefox firefox-* || true

log "Enabling budgie-related services"
# Enable services that budgie might need
systemctl enable pipewire.service || true
systemctl enable pipewire-pulse.service || true
systemctl enable wireplumber.service || true

log "Creating LightDM directories for container compatibility"
mkdir -p /var/lib/lightdm-data/lightdm
chown -R lightdm:lightdm /var/lib/lightdm-data
chmod +x /etc/lightdm/Xsession

log "budgie desktop environment setup complete"
log "Users can select 'budgie' from the login screen after installation"