#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up Budgie Desktop Environment with greetd + gtkgreet"

log "Installing Budgie desktop groups"

# Install the main budgie desktop group
log "Installing budgie desktop group"
dnf5 group install --setopt=install_weak_deps=False --nogpgcheck -y "budgie-desktop"

log "Installing budgie desktop applications group"
dnf5 group install --setopt=install_weak_deps=False --nogpgcheck -y "budgie-desktop-apps"

log "Installing greetd and essential display components"

# Install greetd and additional essential components not in the groups
ADDITIONAL_PACKAGES=(
    greetd
    greetd-gtkgreet
    cage
    polkit-gnome
    xdg-desktop-portal-gtk
)

dnf5 install --setopt=install_weak_deps=False --nogpgcheck -y "${ADDITIONAL_PACKAGES[@]}"

log "Setting up greetd configuration"

# Create greetd configuration directory
mkdir -p /etc/greetd

# Create environments file for gtkgreet session selection
cat > /etc/greetd/environments << 'EOF'
budgie-desktop
sway
bash
zsh
fish
EOF

# Create main greetd configuration using cage compositor for gtkgreet
cat > /etc/greetd/config.toml << 'EOF'
[terminal]
# The VT to run the greeter on. Can be "next", "current" or a number
# designating the VT.
vt = 1

[default_session]
# Using cage compositor to run gtkgreet
# -s enables VT switching to prevent lockout
command = "cage -s -- gtkgreet"
user = "greeter"
EOF

log "Setting up gtkgreet styling"

# Create gtkgreet CSS for SoltrOS theming
mkdir -p /etc/greetd/gtkgreet

cat > /etc/greetd/gtkgreet/style.css << 'EOF'
/* SoltrOS Greetd Theme */
window {
    background-image: url("/usr/share/pixmaps/soltros-gdm.png");
    background-size: cover;
    background-position: center;
    background-repeat: no-repeat;
    background-color: #1e1e1e;
}

.greeter {
    background-color: rgba(30, 30, 30, 0.95);
    border-radius: 10px;
    padding: 20px;
    margin: 20px;
}

.greeter entry {
    background-color: rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 5px;
    padding: 10px;
    color: white;
    font-size: 14px;
}

.greeter button {
    background-color: rgba(52, 101, 164, 0.8);
    border: none;
    border-radius: 5px;
    padding: 10px 20px;
    color: white;
    font-weight: bold;
}

.greeter button:hover {
    background-color: rgba(52, 101, 164, 1);
}

.greeter label {
    color: white;
    font-size: 14px;
}
EOF

# Set up environment variable for gtkgreet to use the CSS
cat > /etc/greetd/gtkgreet-env << 'EOF'
#!/bin/sh
export GTK_THEME=Adwaita:dark
exec gtkgreet -s /etc/greetd/gtkgreet/style.css "$@"
EOF

chmod +x /etc/greetd/gtkgreet-env

# Update greetd config to use the styled gtkgreet
cat > /etc/greetd/config.toml << 'EOF'
[terminal]
vt = 1

[default_session]
command = "cage -s -- /etc/greetd/gtkgreet-env"
user = "greeter"
EOF

log "Setting up Budgie session files"

# Create Budgie Wayland session file
mkdir -p /usr/share/wayland-sessions
cat > /usr/share/wayland-sessions/budgie-desktop-wayland.desktop << 'EOF'
[Desktop Entry]
Name=Budgie Desktop (Wayland)
Comment=An elegant desktop with the advanced Budgie Desktop Environment
Exec=budgie-desktop
Icon=budgie-desktop-symbolic
Type=Application
DesktopNames=Budgie:GNOME
Keywords=GNOME;Budgie;
EOF

# Create Budgie X11 session file for fallback
mkdir -p /usr/share/xsessions
cat > /usr/share/xsessions/budgie-desktop.desktop << 'EOF'
[Desktop Entry]
Name=Budgie Desktop
Comment=An elegant desktop with the advanced Budgie Desktop Environment
Exec=budgie-desktop
Icon=budgie-desktop-symbolic
Type=Application
DesktopNames=Budgie:GNOME
Keywords=GNOME;Budgie;
EOF

log "Setting up system services and users"

# Create greeter user
useradd -r -s /sbin/nologin greeter || true

# Set up PAM configuration for greetd
cat > /etc/pam.d/greetd << 'EOF'
#%PAM-1.0
auth       required   pam_unix.so nullok
account    required   pam_unix.so
password   required   pam_unix.so nullok sha512
session    required   pam_unix.so
session    optional   pam_systemd.so
EOF

log "Setting up GSettings overrides for Budgie"

# Create GSettings overrides for Budgie with SoltrOS theming
mkdir -p /usr/share/glib-2.0/schemas

cat > /usr/share/glib-2.0/schemas/99-soltros-budgie.gschema.override << 'EOF'
[org.gnome.desktop.interface]
icon-theme='Papirus'
gtk-theme='Adwaita-dark'
color-scheme='prefer-dark'

[org.gnome.desktop.wm.preferences]
button-layout=':minimize,maximize,close'

[com.solus-project.budgie-panel]
dark-theme=true

[org.gnome.desktop.background]
picture-uri='file:///usr/share/pixmaps/soltros-gdm.png'
picture-uri-dark='file:///usr/share/pixmaps/soltros-gdm.png'

[org.gnome.desktop.media-handling]
automount=true
automount-open=true
EOF

# Compile schemas
glib-compile-schemas /usr/share/glib-2.0/schemas/

# Remove conflicting packages
log "Removing conflicting display managers and packages"
dnf5 remove -y gdm lightdm sddm firefox firefox-* plasma-discover* gnome-shell gnome-shell-extension-* mutter || true

# Install GNOME Software for package management
log "Install GNOME Software for Budgie"
dnf5 install -y gnome-software gnome-software-rpm-ostree

log "Enabling greetd and related services"

# Enable greetd service
systemctl enable greetd

# Enable essential services for Budgie
systemctl enable pipewire.service || true
systemctl enable pipewire-pulse.service || true
systemctl enable wireplumber.service || true

# Disable conflicting display managers
systemctl disable gdm lightdm sddm || true

# Set up proper permissions for greetd
chmod 755 /etc/greetd
chmod 755 /etc/greetd/gtkgreet-env
chown -R root:greeter /etc/greetd
chmod -R 644 /etc/greetd/*.toml /etc/greetd/environments

log "Creating post-install helper script for greetd troubleshooting"

mkdir -p /usr/share/soltros/scripts

cat > /usr/share/soltros/scripts/greetd-troubleshoot.sh << 'EOF'
#!/bin/bash
# SoltrOS Greetd Troubleshooting Script

echo "=== Greetd Status ==="
systemctl status greetd

echo -e "\n=== Greetd Configuration ==="
cat /etc/greetd/config.toml

echo -e "\n=== Available Sessions ==="
ls -la /usr/share/wayland-sessions/
ls -la /usr/share/xsessions/

echo -e "\n=== Greetd Logs ==="
journalctl -u greetd --no-pager -n 20

echo -e "\n=== Useful Commands ==="
echo "Restart greetd: sudo systemctl restart greetd"
echo "Check greetd config: sudo nano /etc/greetd/config.toml"
echo "Switch to TTY if needed: Ctrl+Alt+F2"
EOF

chmod +x /usr/share/soltros/scripts/greetd-troubleshoot.sh

log "Budgie desktop environment with greetd setup complete"
log "After installation, users will see the gtkgreet login screen"
log "Use /usr/share/soltros/scripts/greetd-troubleshoot.sh for debugging"