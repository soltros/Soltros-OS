@ -0,0 +1,172 @@
#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing Gnome Desktop Environment with LightDM"

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


# Install Gnome desktop group
log "Installing Gnome Desktop Environment"
dnf5 group install --skip-broken "gnome-desktop" -y

# Explicitly install and configure GDM
log "Installing and configuring GDM"
dnf5 install -y gdm

# ADD THIS SECTION HERE:
log "Ensuring GDM user and group setup"

# Recreate gdm group and user if needed  
groupadd -f -g 42 gdm
useradd -r -u 42 -g gdm -d /var/lib/gdm -s /sbin/nologin -c "GNOME Display Manager" gdm || true

# Create necessary directories for gdm
mkdir -p /var/lib/gdm
mkdir -p /var/lib/gdm/.config
mkdir -p /var/log/gdm
mkdir -p /run/gdm
mkdir -p /var/cache/gdm

# Set proper ownership and permissions
chown -R gdm:gdm /var/lib/gdm /var/log/gdm /var/cache/gdm
chmod 755 /var/lib/gdm /var/log/gdm /var/cache/gdm
chmod 700 /var/lib/gdm/.config

# Enable GDM service
log "Enabling GDM service"
systemctl enable gdm

# Update dconf database
dconf update

# Clean up temporary Qt5 packages
log "Cleaning up temporary files"
rm -f /tmp/qt5-qtbase-*.rpm

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

log "Gnome Desktop Environment with LightDM installation complete"
log "System will boot to LightDM login screen with Gnome desktop"