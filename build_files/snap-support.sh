#!/usr/bin/bash
set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up Snap package support for rpm-ostree (based on snapd-in-Silverblue)"

log "Installing snapd package"
dnf5 install --setopt=install_weak_deps=False --nogpgcheck -y snapd

log "Enabling snapd socket"
systemctl enable snapd.socket


chmod +x /opt/soltros-snap/snapd-setup.sh

log "Creating systemd service for snap maintenance"
cat > /etc/systemd/system/soltros-snap.service << 'EOF'
[Unit]
Description=SoltrOS Snap Setup - Maintain snap compatibility
Before=snapd.service
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/share/soltros/scripts/snapd-setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable soltros-snap.service

log "Setting up initial snap directories"
mkdir -p /var/lib/snapd/snap

log "Initial /etc/passwd setup for snap compatibility"
# Update /etc/passwd during build to use /home paths
if grep -q ':/var/home' /etc/passwd; then
    cp /etc/passwd /etc/passwd.backup
    sed -i 's|:/var/home|:/home|' /etc/passwd
    echo "Updated /etc/passwd for snap compatibility during build"
fi

log "Snap support setup complete"
log "Snap will work with classic confinement after first boot"
log "Based on proven snapd-in-Silverblue solution"
