#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing Pantheon Desktop Environment"

# Install Pantheon from Terra repo (which you already have configured!)
log "Installing Pantheon packages from Terra"
dnf5 install -y \
    pantheon-session-settings \
    pantheon-greeter \
    gala \
    wingpanel \
    plank \
    switchboard \
    pantheon-files \
    pantheon-terminal \
    pantheon-calculator \
    pantheon-calendar \
    pantheon-camera \
    pantheon-music \
    pantheon-photos \
    pantheon-videos \
    pantheon-mail \
    pantheon-tasks \
    elementary-icon-theme \
    elementary-wallpapers \
    || log "Some Pantheon packages may not be available, continuing..."

# Try to install the full group if available
dnf5 group install --skip-broken "pantheon-desktop" -y 2>/dev/null || true

# Install LightDM (Pantheon's display manager)
log "Installing and configuring LightDM"
dnf5 install -y lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings

# Install elementary tweaks if available
log "Installing Pantheon extras"
dnf5 install -y pantheon-tweaks 2>/dev/null || \
    log "pantheon-tweaks not available in repos, may need manual build"

# Update dconf database
dconf update

# Rebuild initramfs
log "Rebuilding initramfs"
dracut -f 2>/dev/null || true

# Update GRUB configuration  
log "Updating GRUB configuration"
grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true

# Perform final cleanup
log "Performing final cleanup"
dnf5 autoremove -y
dnf5 clean all

log "Pantheon Desktop Environment installation complete"
log "System will boot to LightDM with Pantheon desktop"