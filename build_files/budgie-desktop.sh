#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up Budgie Desktop Environment with GDM"

log "Installing GDM and essential display components (without GNOME Shell)"

# Install only GDM and essential components, not the full GNOME desktop

dnf5 install --setopt=install_weak_deps=False --nogpgcheck -y "@budgie-desktop @budgie-desktop-apps"

log "Setting up GDM system configuration"

# Create GSettings overrides for Budgie with SoltrOS theming
mkdir -p /usr/share/glib-2.0/schemas

# Create a Budgie-specific schema override
cat > /usr/share/glib-2.0/schemas/99-soltros-budgie.gschema.override << 'EOF'
[org.gnome.desktop.interface]
icon-theme='Papirus'
gtk-theme='Adwaita-dark'
color-scheme='prefer-dark'

[org.gnome.desktop.wm.preferences]
button-layout=':minimize,maximize,close'

[com.solus-project.budgie-panel]
dark-theme=true

[org.gnome.desktop.session]
session-name='budgie-desktop'
EOF

# Compile schemas
glib-compile-schemas /usr/share/glib-2.0/schemas/

# Remove Firefox to replace with Waterfox
log "Removing Firefox in favor of Waterfox"
dnf5 remove -y firefox firefox-* || true

# Remove any GNOME Shell components that might have been pulled in
log "Removing GNOME Shell components"
dnf5 remove -y gnome-shell gnome-shell-extension-* mutter || true

# Remove Discover if it exists
log "Remove Discover"
dnf5 remove -y plasma-discover* || true

# Install Budgie-compatible software center
log "Install GNOME Software for Budgie"
dnf5 install -y gnome-software gnome-software-rpm-ostree

log "Enabling display and session services"
# Enable services that Budgie needs
systemctl enable pipewire.service || true
systemctl enable pipewire-pulse.service || true
systemctl enable wireplumber.service || true

# Enable GDM (force override any existing display manager)
systemctl enable gdm -f

# Disable any conflicting display managers
systemctl disable lightdm || true
systemctl disable sddm || true

log "Budgie desktop environment with GDM setup complete"
log "Users will get Budgie desktop by default after installation"