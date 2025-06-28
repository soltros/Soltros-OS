#!/usr/bin/bash
# build_files/lightdm-setup.sh
# This handles LightDM setup for bootc deployments
set -euo pipefail

log() {
  echo "=== $* ==="
}

log "Setting up LightDM for bootc deployment"

# Fix PAM fingerprint issue first
log "Fixing PAM fingerprint configuration"
if [ -f /etc/pam.d/lightdm ]; then
    sed -i '/pam_fprintd/d' /etc/pam.d/lightdm
fi
if [ -f /etc/pam.d/lightdm-greeter ]; then
    sed -i '/pam_fprintd/d' /etc/pam.d/lightdm-greeter
fi
if [ -f /etc/pam.d/login ]; then
    sed -i '/pam_fprintd/d' /etc/pam.d/login
fi

# Create tmpfiles configuration for bootc deployments
# This ensures directories and user are created on first boot
log "Creating tmpfiles and sysusers configuration"
cat > /usr/lib/tmpfiles.d/soltros-lightdm.conf << 'EOF'
# SoltrOS LightDM directories
d /var/lib/lightdm 0750 lightdm lightdm -
d /var/lib/lightdm-data 0750 lightdm lightdm -
d /var/cache/lightdm 0750 lightdm lightdm -
d /var/log/lightdm 0750 lightdm lightdm -
d /run/lightdm 0755 lightdm lightdm -
EOF

# Create sysusers configuration to ensure lightdm user exists
cat > /usr/lib/sysusers.d/soltros-lightdm.conf << 'EOF'
# SoltrOS LightDM user
u lightdm 968 "Light Display Manager" /var/lib/lightdm /sbin/nologin
EOF

# Create a systemd service to fix LightDM on first boot
log "Creating first-boot LightDM setup service"
cat > /usr/lib/systemd/system/soltros-lightdm-setup.service << 'EOF'
[Unit]
Description=SoltrOS LightDM Setup
Before=lightdm.service
ConditionPathExists=!/var/lib/soltros/.lightdm-setup-done

[Service]
Type=oneshot
ExecStart=/usr/bin/bash -c 'systemd-sysusers /usr/lib/sysusers.d/soltros-lightdm.conf && systemd-tmpfiles --create /usr/lib/tmpfiles.d/soltros-lightdm.conf && mkdir -p /var/lib/soltros && touch /var/lib/soltros/.lightdm-setup-done'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the setup service
systemctl enable soltros-lightdm-setup.service

# Ensure lightdm service is enabled
log "Enabling LightDM service"
systemctl enable lightdm.service
systemctl disable gdm.service 2>/dev/null || true

log "LightDM bootc setup complete"