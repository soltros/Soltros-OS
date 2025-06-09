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

log "Creating /home symlink for /var/home compatibility"
# Fedora immutable distros use /var/home instead of /home
# This symlink makes snaps work with the /var/home directory structure
ln -sf /var/home /home

log "Snap support setup complete"
log "Users can now install both strictly confined and classic snaps"
