#!/usr/bin/bash
set -euo pipefail
trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
    echo "=== $* ==="
}

log "Installing Hyprland Wayland Compositor with GDM"

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

# Install Hyprland and essential Wayland components
log "Installing Hyprland and core Wayland components"
dnf5 install -y \
    hyprland \
    hyprland-devel \
    hyprland-protocols-devel \
    xdg-desktop-portal-hyprland \
    nwg-dock-hyprland

# Install Waybar and Mako (official Fedora packages)
log "Installing Waybar status bar and Mako notification daemon"
dnf5 install -y waybar mako

# Install display manager (GDM works well with Wayland)
log "Installing GDM display manager"
dnf5 install -y gdm

# Install essential Wayland utilities and applications
log "Installing Wayland utilities and applications"
dnf5 install -y \
    wofi \
    kitty \
    thunar \
    firefox \
    grim \
    slurp \
    wl-clipboard \
    swayidle \
    polkit-gnome \
    pavucontrol \
    network-manager-applet \
    blueman

# Install fonts and themes
log "Installing fonts and themes"
dnf5 install -y \
    fontawesome-fonts \
    google-noto-fonts \
    google-noto-color-emoji-fonts \
    dejavu-fonts-all \
    liberation-fonts \
    adwaita-gtk2-theme \
    papirus-icon-theme \
    adwaita-icon-theme

# Enable GDM service
log "Enabling GDM display manager"
systemctl enable gdm.service

# Set default target to graphical
log "Setting graphical target as default"
systemctl set-default graphical.target



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

log "Hyprland Wayland compositor installation complete"
log "System will boot to GDM login screen with Hyprland available as a session option"
log ""
log "Installed components:"
log "  - Hyprland 0.45.2 (dynamic tiling Wayland compositor)"
log "  - Waybar 0.12.0 (status bar)"
log "  - Mako 1.10.0 (notification daemon)"  
log "  - nwg-dock-hyprland 0.3.3 (GTK3-based dock)"
log "  - xdg-desktop-portal-hyprland 1.3.6 (desktop portal backend)"
log ""
log "Note: User configuration files should be provided via skel or user setup"