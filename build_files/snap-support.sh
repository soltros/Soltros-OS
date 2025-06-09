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

log "Setting up bind mount for /var/home to /home compatibility"
# Remove any existing /home symlink that would prevent the bind mount
rm -rf /home

# Create /home directory for mounting
mkdir -p /home

# Create systemd mount unit to bind mount /var/home to /home
# This is the official solution from Snapcraft documentation
mkdir -p /etc/systemd/system

cat > /etc/systemd/system/home.mount << 'EOF'
[Unit]
Description=Bind mount /var/home to /home for snap compatibility
Before=snapd.service

[Mount]
What=/var/home
Where=/home
Type=none
Options=bind

[Install]
WantedBy=local-fs.target
EOF

systemctl enable home.mount

log "Configuring /etc/passwd for /home paths"
# Update /etc/passwd to use /home instead of /var/home for snap compatibility
# This makes snap see user homes under /home (which is bind mounted to /var/home)
sed -i 's|/var/home|/home|g' /etc/passwd

log "Snap support setup complete"
log "Users can now install both strictly confined and classic snaps"
log "Home directories are bind mounted from /var/home to /home"
