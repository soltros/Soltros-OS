#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Enabling Tailscale"
systemctl enable tailscaled.service

log "Enabling Sddm"
systemctl enable sddm.service -f

log "Enable binaries"
mkdir -p /usr/share/soltros/bin/
git clone --depth=1 https://github.com/soltros/Soltros-OS-Components.git /tmp/components && \
    cp /tmp/components/*.sh /usr/share/soltros/bin/ 2>/dev/null || true && \
    chmod +x /usr/share/soltros/bin/*.sh && \
    rm -rf /tmp/components

log "Setting permissions for Waybar scripts"
if [ -d /etc/xdg/waybar/scripts ]; then
    chmod +x /etc/xdg/waybar/scripts/*.sh 2>/dev/null || true
fi
if [ -d /etc/skel/waybar/scripts ]; then
    chmod +x /etc/skel/waybar/scripts/*.sh 2>/dev/null || true
fi

log "Setting permissions for Ashell binary"
if [ -f /usr/bin/ashell ]; then
    chmod +x /usr/bin/ashell
fi

log "Enable services for new users in /etc/skel"
mkdir -p /etc/skel/.config/systemd/user/graphical-session.target.wants
ln -sf /usr/lib/systemd/user/hyprpolkitagent.service \
    /etc/skel/.config/systemd/user/graphical-session.target.wants/hyprpolkitagent.service

log "Enable user services for existing users (bootc switch compatibility)"
# Apply systemd user presets to all existing home directories
for homedir in /home/* /var/home/*; do
    if [ -d "$homedir" ] && [ "$(basename "$homedir")" != "lost+found" ]; then
        username=$(basename "$homedir")
        if id "$username" &>/dev/null; then
            # Create systemd user directory if it doesn't exist
            sudo -u "$username" mkdir -p "$homedir/.config/systemd/user/graphical-session.target.wants" 2>/dev/null || true
            # Enable the service for this user
            sudo -u "$username" ln -sf /usr/lib/systemd/user/hyprpolkitagent.service \
                "$homedir/.config/systemd/user/graphical-session.target.wants/hyprpolkitagent.service" 2>/dev/null || true
        fi
    fi
done
