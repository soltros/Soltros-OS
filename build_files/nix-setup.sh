#!/usr/bin/bash
# SoltrOS: Nix Package Manager Setup Script
# Installs Nix package manager for additional package management

set ${SET_X:+-x} -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing Nix package manager"

# Create nix user and group
groupadd -r nixbld
for i in $(seq 1 10); do
    useradd -r -g nixbld -G nixbld -d /var/empty -s /sbin/nologin \
            -c "Nix build user $i" nixbld$i
done

# Create necessary directories
mkdir -p /nix
mkdir -p /etc/nix

# Download and install Nix
NIX_VERSION="2.24.10"  # Latest stable as of writing
curl -L https://releases.nixos.org/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}-x86_64-linux.tar.xz | tar -xJ

# Install Nix
cd nix-${NIX_VERSION}-x86_64-linux
./install --daemon --yes

# Clean up installer
cd ..
rm -rf nix-${NIX_VERSION}-x86_64-linux

log "Configuring Nix for multi-user setup"

# Create nix configuration
cat > /etc/nix/nix.conf << 'EOF'
# SoltrOS Nix Configuration
build-users-group = nixbld
experimental-features = nix-command flakes
auto-optimise-store = true
trusted-users = root @wheel
EOF

# Setup Nix profile scripts
mkdir -p /etc/profile.d

cat > /etc/profile.d/nix.sh << 'EOF'
# Nix package manager setup
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
EOF

# Setup Nix for Fish shell
mkdir -p /etc/fish/conf.d
cat > /etc/fish/conf.d/nix.fish << 'EOF'
# Nix package manager setup for Fish
if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    bass source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
end
EOF

# Create systemd service for nix-daemon
cat > /etc/systemd/system/nix-daemon.service << 'EOF'
[Unit]
Description=Nix Daemon
Documentation=man:nix-daemon man:nix.conf
RequiresMountsFor=/nix/store
RequiresMountsFor=/nix/var
ConditionPathExists=/nix/store

[Service]
ExecStart=/nix/var/nix/profiles/default/bin/nix-daemon --daemon
KillMode=process
LimitNOFILE=1048576
TasksMax=infinity
Type=notify

[Install]
WantedBy=multi-user.target
EOF

# Create systemd socket for nix-daemon
cat > /etc/systemd/system/nix-daemon.socket << 'EOF'
[Unit]
Description=Nix Daemon Socket
Documentation=man:nix-daemon man:nix.conf

[Socket]
ListenStream=/nix/var/nix/daemon-socket/socket

[Install]
WantedBy=sockets.target
EOF

# Enable nix-daemon
systemctl enable nix-daemon.socket

# Set proper permissions
chown -R root:nixbld /nix
chmod 1775 /nix/store

log "Setting up Nix channels"

# Setup default channel for all users
/nix/var/nix/profiles/default/bin/nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
/nix/var/nix/profiles/default/bin/nix-channel --update

log "Nix package manager installation completed"
