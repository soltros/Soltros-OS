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
