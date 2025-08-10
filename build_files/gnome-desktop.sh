#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing GNOME Desktop Environment with GDM"

# Remove any existing Plymouth components first (same as KDE)
log "Removing Plymouth boot splash (for clean boot)"
dnf5 remove -y plymouth* || true
systemctl disable plymouth-start.service plymouth-read-write.service plymouth-quit.service plymouth-quit-wait.service plymouth-reboot.service plymouth-kexec.service plymouth-halt.service plymouth-poweroff.service 2>/dev/null || true
rm -rf /usr/share/plymouth /usr/lib/plymouth /etc/plymouth
rm -f /usr/lib/systemd/system/plymouth* /usr/lib/systemd/system/*/plymouth*
rm -f /usr/bin/plymouth /usr/sbin/plymouthd

# Clean up GRUB config to remove Plymouth references
sed -i 's/rhgb quiet//' /etc/default/grub 2>/dev/null || true
sed -i 's/splash//' /etc/default/grub 2>/dev/null || true
sed -i '/plymouth/d' /etc/dracut.conf.d/* 2>/dev/null || true
echo 'omit_dracutmodules+=" plymouth "' > /etc/dracut.conf.d/99-disable-plymouth.conf

# Install GNOME desktop group
log "Installing GNOME Desktop Environment"
dnf5 group install --skip-broken "gnome-desktop" -y

# Install additional GNOME applications and tools
log "Installing additional GNOME applications and tools"
dnf5 install --skip-broken -y \
    gnome-tweaks \
    gnome-extensions-app \
    file-roller \
    dconf-editor

# Enable GDM display manager
log "Enabling GDM display manager"
systemctl enable gdm.service

# Disable other display managers that might conflict
systemctl disable sddm.service 2>/dev/null || true
systemctl disable lightdm.service 2>/dev/null || true

# Enabling Flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Set up GNOME-specific configurations
log "Configuring GNOME defaults"

# Create GNOME dconf profile
mkdir -p /etc/dconf/profile
cat > /etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF

# Update dconf database with existing SoltrOS settings
dconf update

# Compile dconf settings
dconf compile /etc/dconf/db/local /etc/dconf/db/local.d/

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

log "GNOME Desktop Environment with GDM installation complete"
log "System will boot to GDM login screen with GNOME desktop"