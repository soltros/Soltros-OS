#!/usr/bin/bash
# SoltrOS: Nix Daemon Setup Script
# Sets up systemd services for Nix daemon

set ${SET_X:+-x} -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up Nix daemon systemd services"

# DEPENDENCY: Ensure nix-setup.sh has completed successfully
if [ ! -d "/nix/store" ]; then
    log "ERROR: /nix/store not found - nix-setup.sh must run first"
    exit 1
fi

if [ ! -f "/nix/var/nix/profiles/default/bin/nix-daemon" ]; then
    log "ERROR: nix-daemon binary not found - nix-setup.sh did not complete properly"
    exit 1
fi

if [ ! -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
    log "ERROR: nix-daemon.sh profile script not found - nix-setup.sh did not complete properly"
    exit 1
fi

# Verify nix-daemon binary is executable
if [ ! -x "/nix/var/nix/profiles/default/bin/nix-daemon" ]; then
    log "ERROR: nix-daemon binary not executable"
    exit 1
fi

log "Dependencies verified - Nix installation is complete"

# Create systemd service for nix-daemon
log "Creating nix-daemon.service"
cat > /etc/systemd/system/nix-daemon.service << 'EOF'
[Unit]
Description=Nix Daemon
Documentation=man:nix-daemon man:nix.conf
RequiresMountsFor=/nix/store
RequiresMountsFor=/nix/var
ConditionPathExists=/nix/store
After=network.target

[Service]
ExecStart=/nix/var/nix/profiles/default/bin/nix-daemon --daemon
KillMode=process
LimitNOFILE=1048576
TasksMax=infinity
Type=simple
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create systemd socket for nix-daemon
log "Creating nix-daemon.socket"
cat > /etc/systemd/system/nix-daemon.socket << 'EOF'
[Unit]
Description=Nix Daemon Socket
Documentation=man:nix-daemon man:nix.conf

[Socket]
ListenStream=/nix/var/nix/daemon-socket/socket
SocketMode=0666
SocketUser=root
SocketGroup=nixbld

[Install]
WantedBy=sockets.target
EOF

# Create directory for daemon socket
mkdir -p /nix/var/nix/daemon-socket

# Set proper permissions
chown root:nixbld /nix/var/nix/daemon-socket
chmod 755 /nix/var/nix/daemon-socket

# Reload systemd to pick up new services
systemctl daemon-reload

# Enable and start services
log "Enabling and starting nix-daemon services"
systemctl enable nix-daemon.socket
systemctl enable nix-daemon.service

# Start the socket (this will auto-start the service when needed)
systemctl start nix-daemon.socket

# Test that the daemon can start
log "Testing nix-daemon startup"
if systemctl start nix-daemon.service; then
    log "nix-daemon started successfully"
    systemctl status nix-daemon.service --no-pager -l
else
    log "Warning: nix-daemon failed to start, but services are enabled for boot"
    systemctl status nix-daemon.service --no-pager -l || true
fi

log "Nix daemon systemd services created, enabled, and started"
