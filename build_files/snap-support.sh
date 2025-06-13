#!/usr/bin/bash
set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up Snap package support using systemd mount units (Nelson Aloysio method)"

log "Installing snapd package"
dnf5 install --setopt=install_weak_deps=False --nogpgcheck -y snapd

log "Enabling snapd socket"
systemctl enable snapd.socket

log "Creating template service for OSTree root filesystem modifications"
cat > /etc/systemd/system/mkdir-rootfs@.service << 'EOF'
[Unit]
Description=Enable mount points in / for OSTree
DefaultDependencies=no

[Service]
Type=oneshot
ExecStartPre=chattr -i /
ExecStart=/bin/sh -c "[ -L '%f' ] && rm '%f'; mkdir -p '%f'"
ExecStopPost=chattr +i /
EOF

log "Creating snap symlink service (required for classic snaps)"
cat > /etc/systemd/system/snap-symlink.service << 'EOF'
[Unit]
Description=Creates /snap symlink for OSTree (required for classic snaps)
DefaultDependencies=no

[Service]
Type=oneshot
ExecStartPre=chattr -i /
ExecStart=/usr/bin/ln -sf /var/lib/snapd/snap /snap
ExecStartPost=chattr +i /

[Install]
WantedBy=snapd.socket
EOF

log "Creating home mount unit (bind mount /var/home to /home)"
cat > /etc/systemd/system/home.mount << 'EOF'
[Unit]
After=mkdir-rootfs@home.service
Wants=mkdir-rootfs@home.service
Before=snapd.socket

[Mount]
What=/var/home
Where=/home
Options=bind
Type=none

[Install]
WantedBy=snapd.socket
EOF

log "Creating alternative snap symlink service (fallback if mount doesn't work)"
cat > /etc/systemd/system/snap-mount.service << 'EOF'
[Unit]
Description=Bind mount /var/lib/snapd/snap to /snap (alternative to symlink)
After=mkdir-rootfs@snap.service
Wants=mkdir-rootfs@snap.service
Before=snapd.socket

[Service]
Type=oneshot
ExecStartPre=chattr -i /
ExecStart=/bin/sh -c "[ -L '/snap' ] && rm '/snap'; mkdir -p '/snap' && mount --bind /var/lib/snapd/snap /snap"
ExecStartPost=chattr +i /
RemainAfterExit=yes

[Install]
WantedBy=snapd.socket
EOF

log "Enabling systemd services"
systemctl enable snap-symlink.service  # Use symlink by default (required for classic snaps)
systemctl enable home.mount
# Both snap approaches available:
# - snap-symlink.service (enabled) - works with classic snaps
# - snap-mount.service (disabled) - alternative bind mount approach
echo "Both snap approaches installed:"
echo "  Active: snap-symlink.service (for classic snap compatibility)"  
echo "  Available: snap-mount.service (alternative bind mount)"
echo "To switch: sudo systemctl disable snap-symlink.service && sudo systemctl enable snap-mount.service"

log "Setting up initial snap directories"
mkdir -p /var/lib/snapd/snap

log "Updating /etc/passwd for snap compatibility"
# Update /etc/passwd during build to use /home paths
if grep -q ':/var/home' /etc/passwd; then
    cp /etc/passwd /etc/passwd.backup
    sed -i 's|:/var/home|:/home|' /etc/passwd
    echo "Updated /etc/passwd: /var/home -> /home"
fi

log "Snap support setup complete using systemd mount units"
log "This approach uses proper systemd services instead of manual filesystem hacks"
log "If snap.mount fails, you can try: sudo systemctl disable snap.mount && sudo systemctl enable snap-symlink.service"
