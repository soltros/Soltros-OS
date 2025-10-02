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
log "Installing COSMIC desktop environment packages"

# Install COSMIC applications group  
log "Installing COSMIC desktop apps group"
dnf5 group install --setopt=install_weak_deps=False --nogpgcheck -y "cosmic-desktop-apps"
log "Installing COSMIC desktop environment packages"

log "Setting up COSMIC system configuration"
# Core COSMIC desktop system components (missing from groups)
COSMIC_CORE=(
    cosmic-comp
    cosmic-panel
    cosmic-launcher
    cosmic-settings
    cosmic-settings-daemon
    cosmic-notifications
    cosmic-workspaces
    cosmic-screenshot
    cosmic-osd
    cosmic-app-library
    cosmic-applets
    cosmic-bg
    cosmic-greeter
    cosmic-idle
    cosmic-randr
    xdg-desktop-portal-cosmic
)

# Mandatory COSMIC desktop packages (from group)
COSMIC_MANDATORY=(
    cosmic-edit
    cosmic-files
    cosmic-session
    cosmic-store
    cosmic-term
)

# Default COSMIC desktop packages (from group)
COSMIC_DEFAULT=(
    cosmic-player
    flatpak
    gnome-keyring
    gnome-keyring-pam
    initial-setup-gui
    toolbox
)

# COSMIC theming and configuration
COSMIC_THEMING=(
    cosmic-icon-theme
    cosmic-wallpapers
    cosmic-config-fedora
    initial-setup-gui-wayland-cosmic
)

log "Installing core COSMIC system components"
for package in "${COSMIC_CORE[@]}"; do
    dnf5 install --setopt=install_weak_deps=False --nogpgcheck -y "$package"
    log "Installed $package"
done

log "Installing mandatory COSMIC packages"
for package in "${COSMIC_MANDATORY[@]}"; do
    dnf5 install --setopt=install_weak_deps=False --nogpgcheck -y "$package"
    log "Installed $package"
done

# Create GSettings overrides for COSMIC with SoltrOS theming
mkdir -p /usr/share/glib-2.0/schemas
log "Installing default COSMIC packages"
for package in "${COSMIC_DEFAULT[@]}"; do
    dnf5 install --setopt=install_weak_deps=False --nogpgcheck -y "$package"
    log "Installed $package"
done

log "Installing COSMIC theming and configuration"
for package in "${COSMIC_THEMING[@]}"; do
    dnf5 install --setopt=install_weak_deps=False --nogpgcheck -y "$package"
    log "Installed $package"
done

# COSMIC desktop supplementary applications
COSMIC_APPS=(
    ark
    gnome-calculator
    gnome-disk-utility
    gnome-system-monitor
    nheko
    okular
    rhythmbox
    thunderbird
)

log "Installing COSMIC supplementary applications"
for package in "${COSMIC_APPS[@]}"; do
    dnf5 install --setopt=install_weak_deps=False --nogpgcheck -y "$package"
    log "Installed $package"
done

log "Setting up COSMIC system configuration"

# Compile schemas
glib-compile-schemas /usr/share/glib-2.0/schemas/