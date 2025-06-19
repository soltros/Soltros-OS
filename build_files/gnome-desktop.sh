#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up gnome Desktop Environment"

log "Installing gnome desktop environment from official Fedora groups"

# Install the main gnome desktop group
log "Installing gnome desktop group"
dnf5 group install --setopt=install_weak_deps=False --nogpgcheck -y "gnome-desktop"

log "Setting up gnome system configuration"

# Create GSettings overrides for gnome with SoltrOS theming
mkdir -p /usr/share/glib-2.0/schemas

# Compile schemas
glib-compile-schemas /usr/share/glib-2.0/schemas/

log "Enabling gnome-related services"
# Enable services that gnome might need
systemctl enable pipewire.service || true
systemctl enable pipewire-pulse.service || true
systemctl enable wireplumber.service || true

log "gnome desktop environment setup complete"
log "Users can select 'gnome' from the login screen after installation"
log "Note: gnome is a Wayland-only desktop environment"
