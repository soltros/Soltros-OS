#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing deepin Desktop Environment with LightDM"

# Remove any existing Plymouth components first (as you were doing)
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

# Install deepin desktop group
log "Installing deepin Desktop Environment"
dnf5 group install --skip-broken --setopt=install_weak_deps=False "deepin-desktop" -y
dnf5 group install --skip-broken --setopt=install_weak_deps=False "deepin-desktop-apps" -y

# Install LightDM display manager and greeters
log "Installing LightDM display manager"
dnf5 install -y \
    lightdm \
    slick-greeter

# Configure LightDM as the default display manager
log "Configuring LightDM as default display manager"
systemctl disable gdm.service 2>/dev/null || true
systemctl disable sddm.service 2>/dev/null || true
systemctl enable lightdm.service

# Set up systemd user directories for LightDM
log "Setting up LightDM user directories"
mkdir -p /var/lib/lightdm
mkdir -p /var/cache/lightdm
mkdir -p /var/log/lightdm
mkdir -p /run/lightdm

# Create lightdm user if it doesn't exist
if ! id lightdm >/dev/null 2>&1; then
    useradd -r -s /sbin/nologin -d /var/lib/lightdm lightdm
fi

# Set proper ownership
chown lightdm:lightdm /var/lib/lightdm
chown lightdm:lightdm /var/cache/lightdm  
chown lightdm:lightdm /var/log/lightdm
chown lightdm:lightdm /run/lightdm

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

log "deepin Desktop Environment with LightDM installation complete"
log "System will boot to LightDM login screen with deepin desktop"