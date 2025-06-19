#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up cinnamon Desktop Environment with greetd + gtkgreet"

log "Installing cinnamon desktop groups"

# Install Plasma groups
log "Installing KDE Plasma desktop group"
dnf5 group install --setopt=install_weak_deps=False --nogpgcheck -y "kde-desktop"
dnf5 group install --setopt=install_weak_deps=False --nogpgcheck -y "kde-apps"
dnf5 group install --setopt=install_weak_deps=False --nogpgcheck -y "kde-media"

log "Installing greetd and essential display components"

# Install greetd and additional essential components not in the groups
ADDITIONAL_PACKAGES=(
    pipewire
    wireplumber  
)

dnf5 install --setopt=install_weak_deps=False  --skip-unavailable --nogpgcheck -y "${ADDITIONAL_PACKAGES[@]}"

# Remove conflicting packages
log "Removing conflicting display managers and packages"
dnf5 remove -y firefox firefox-* || true

log "Enabling greetd and related services"

# Enable greetd service
systemctl enable sddm -f

# Enable essential services for cinnamon
systemctl enable pipewire.service || true
systemctl enable pipewire-pulse.service || true
systemctl enable wireplumber.service || true
