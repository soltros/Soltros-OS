#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing Cinnamon Desktop Environment with LightDM"

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

# Install Cinnamon desktop group
log "Installing Cinnamon Desktop Environment"
dnf5 group install --skip-broken "cinnamon-desktop" -y

# Install LightDM display manager and greeters
log "Installing LightDM display manager"
dnf5 install -y \
    lightdm \
    lightdm-gtk \
    lightdm-gtk-greeter-settings \
    slick-greeter

# Configure LightDM as the default display manager
log "Configuring LightDM as default display manager"
systemctl disable gdm.service 2>/dev/null || true
systemctl disable sddm.service 2>/dev/null || true
systemctl enable lightdm.service

# Configure LightDM to use Cinnamon by default
log "Configuring LightDM for Cinnamon"
cat > /etc/lightdm/lightdm.conf << 'EOF'
[LightDM]
greeter-user=lightdm
greeter-session=lightdm-gtk-greeter
user-session=cinnamon
greeter-setup-script=
greeter-hide-users=false
greeter-allow-guest=false

[Seat:*]
type=local
pam-service=lightdm
pam-autologin-service=lightdm-autologin
pam-greeter-service=lightdm-greeter
session-wrapper=/etc/lightdm/Xsession
greeter-session=lightdm-gtk-greeter
user-session=cinnamon
allow-user-switching=true
allow-guest=false
greeter-show-manual-login=true
greeter-hide-users=false
EOF

# Configure LightDM GTK greeter with SoltrOS branding
log "Configuring LightDM GTK greeter theme"
cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'EOF'
[greeter]
background=/usr/share/pixmaps/soltros-gdm.png
theme-name=Adwaita-dark
icon-theme-name=Papirus
font-name=Cantarell 11
xft-antialias=true
xft-dpi=96
xft-hintstyle=hintslight
xft-rgba=rgb
show-indicators=~host;~spacer;~clock;~spacer;~layout;~session;~a11y;~power
show-clock=true
clock-format=%a, %b %d  %H:%M
position=50%,center 50%,center
default-user-image=/usr/share/pixmaps/nobody.png
hide-user-image=false
round-user-image=true
highlight-logged-user=true
panel-position=bottom
active-monitor=#cursor
EOF

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

# Configure Cinnamon as default session
log "Setting Cinnamon as default session"
mkdir -p /etc/skel/.dmrc
cat > /etc/skel/.dmrc << 'EOF'
[Desktop]
Session=cinnamon
EOF

# Set up Cinnamon default settings via dconf
log "Applying Cinnamon default settings"
mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/00-cinnamon-defaults << 'EOF'
[org/cinnamon]
enabled-applets=['panel1:left:0:menu@cinnamon.org:0', 'panel1:left:1:show-desktop@cinnamon.org:1', 'panel1:left:2:panel-launchers@cinnamon.org:2', 'panel1:left:3:window-list@cinnamon.org:3', 'panel1:right:0:notifications@cinnamon.org:4', 'panel1:right:1:user@cinnamon.org:5', 'panel1:right:2:removable-drives@cinnamon.org:6', 'panel1:right:3:keyboard@cinnamon.org:7', 'panel1:right:4:network@cinnamon.org:8', 'panel1:right:5:sound@cinnamon.org:9', 'panel1:right:6:power@cinnamon.org:10', 'panel1:right:7:calendar@cinnamon.org:11']
panel-launchers=['firefox.desktop', 'org.gnome.Terminal.desktop', 'nemo.desktop']
favorite-apps=['firefox.desktop', 'org.gnome.Terminal.desktop', 'nemo.desktop', 'org.gnome.Calculator.desktop']

[org/cinnamon/desktop/interface]
gtk-theme='Adwaita-dark'
icon-theme='Papirus'
cursor-theme='Adwaita'
font-name='Cantarell 11'

[org/cinnamon/desktop/wm/preferences]
theme='Adwaita'
button-layout=':minimize,maximize,close'

[org/cinnamon/theme]
name='Adwaita-dark'

[org/cinnamon/desktop/background]
picture-uri='file:///usr/share/pixmaps/soltros-gdm.png'
picture-options='zoom'
color-shading-type='solid'
primary-color='#023c88'
EOF

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

log "Cinnamon Desktop Environment with LightDM installation complete"
log "System will boot to LightDM login screen with Cinnamon desktop"