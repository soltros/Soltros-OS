#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing Liri Desktop Environment with LightDM"

# Install Liri packages
log "Installing Liri"

sudo dnf copr enable plfiorini/liri-nightly

sudo dnf5 install -y \
    sddm \
    liri-networkmanager \
    liri-platformtheme \
    liri-power-manager \
    liri-pulseaudio \
    liri-screencast \
    liri-screenshot \
    liri-settings \
    liri-shell \
    liri-wallpapers \
    qml-xwayland \
    xdg-desktop-portal-liri \
    paper-icon-theme \
    liri-color-schemes

sudo dnf5 install -y \
    liri-appcenter \
    liri-calculator \
    liri-files \
    liri-terminal \
    liri-browser \
    liri-text

# Update dconf database
dconf update


# Rebuild initramfs without Plymouth
log "Rebuilding initramfs"
dracut -f 2>/dev/null || true

# Update GRUB configuration  
log "Updating GRUB configuration"
grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true

# Perform final cleanup
log "Performing final cleanup"
dnf5 autoremove -y
dnf5 clean all

log "Liri Desktop Environment with SDDM installation complete"
log "System will boot to SDDM login screen with KDE desktop"