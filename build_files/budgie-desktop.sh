#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up Budgie Desktop Environment with greetd + gtkgreet"

log "Installing Budgie desktop groups"

# Install the main budgie desktop group
log "Installing budgie desktop group"
dnf5 group install --setopt=install_weak_deps=False --nogpgcheck -y "budgie-desktop"

log "Installing budgie desktop applications group"
dnf5 group install --setopt=install_weak_deps=False --nogpgcheck -y "budgie-desktop-apps"

log "Installing greetd and essential display components"

# Install greetd and additional essential components not in the groups
ADDITIONAL_PACKAGES=(
    greetd
    greetd-gtkgreet
    cage
    polkit-gnome
    xdg-desktop-portal-gtk
)

dnf5 install --setopt=install_weak_deps=False  --skip-unavailable --nogpgcheck -y "${ADDITIONAL_PACKAGES[@]}"

log "Setting up greetd configuration"

chmod +x /etc/greetd/gtkgreet-env

log "Setting up system services and users"

# Compile schemas
glib-compile-schemas /usr/share/glib-2.0/schemas/

# Remove conflicting packages
log "Removing conflicting display managers and packages"
dnf5 remove -y firefox firefox-* || true

# Install GNOME Software for package management
log "Install GNOME Software for Budgie"
dnf5 install -y gnome-software gnome-software-rpm-ostree

log "Enabling greetd and related services"

# Enable greetd service
systemctl enable greetd

# Enable essential services for Budgie
systemctl enable pipewire.service || true
systemctl enable pipewire-pulse.service || true
systemctl enable wireplumber.service || true

# Disable conflicting display managers
systemctl disable gdm lightdm sddm || true

# Set up proper permissions for greetd
chmod 755 /etc/greetd
chmod 755 /etc/greetd/gtkgreet-env
chown -R root:greeter /etc/greetd
chmod -R 644 /etc/greetd/*.toml /etc/greetd/environments

log "Creating post-install helper script for greetd troubleshooting"

mkdir -p /usr/share/soltros/scripts

chmod +x /usr/share/soltros/scripts/greetd-troubleshoot.sh

log "Budgie desktop environment with greetd setup complete"
log "After installation, users will see the gtkgreet login screen"
log "Use /usr/share/soltros/scripts/greetd-troubleshoot.sh for debugging"