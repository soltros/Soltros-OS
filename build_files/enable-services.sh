#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Enabling Tailscale"
systemctl enable tailscaled.service

log "Enable Greetd failsafe"
systemctl enable -f greetd.service

log "Enable binaries"
mkdir -p /usr/share/soltros/bin/
git clone --depth=1 https://github.com/soltros/Soltros-OS-Components.git /tmp/components && \
    cp /tmp/components/*.sh /usr/share/soltros/bin/ 2>/dev/null || true && \
    chmod +x /usr/share/soltros/bin/*.sh && \
    rm -rf /tmp/components

chmod +x /usr/share/soltros/bin/cosmic-settings-backup/cbackup
chmod +x /usr/share/soltros/bin/cosmic-settings-backup/cosmic-settings-backup.desktop
mv /usr/share/soltros/bin/cosmic-settings-backup/cosmic-settings-backup.desktop /usr/share/applications/