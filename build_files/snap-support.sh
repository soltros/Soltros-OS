#!/usr/bin/bash
set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up Snap package support"

log "Installing snapd package"
dnf5 install --setopt=install_weak_deps=False --nogpgcheck -y snapd

log "Enabling snapd socket (required for snap to work)"
systemctl enable snapd.socket

log "Creating /snap symlink for classic confinement support"
# This symlink is required for classic snaps (like VS Code, Node.js, etc.) to work properly
ln -sf /var/lib/snapd/snap /snap

log "Setting up snapd for /var/home compatibility"
# Create a systemd service to configure snapd after it starts
# This sets the homedirs system option to support /var/home
mkdir -p /etc/systemd/system
cat > /etc/systemd/system/snapd-configure-homedirs.service << 'EOF'
[Unit]
Description=Configure snapd homedirs for /var/home
After=snapd.service
Requires=snapd.service

[Service]
Type=oneshot
ExecStart=/usr/bin/snap set system homedirs=/var/home
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable snapd-configure-homedirs.service

log "Snap support setup complete"
log "Users can now install both strictly confined and classic snaps with /var/home support"
