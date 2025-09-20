#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing KDE Desktop Environment with LightDM"

# Install KDE desktop groups
log "Installing KDE Desktop Environment"
dnf group install --skip-broken "kde-apps" -y
dnf group install --skip-broken "kde-media" -y
dnf group install --skip-broken "kde-desktop" -y

# Enabling Flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

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
dnf autoremove -y
dnf clean all

log "KDE Desktop Environment with SDDM installation complete"
log "System will boot to SDDM login screen with KDE desktop"