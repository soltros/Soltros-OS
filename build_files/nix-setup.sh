#!/usr/bin/bash
# SoltrOS: Nix Package Manager Setup Script
# Installs Nix package manager for additional package management

set ${SET_X:+-x} -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing Nix package manager"

# Check if nixbld group exists and get its GID
if getent group nixbld >/dev/null 2>&1; then
    NIXBLD_GID=$(getent group nixbld | cut -d: -f3)
    log "Found existing nixbld group with GID $NIXBLD_GID"
    export NIX_BUILD_GROUP_ID=$NIXBLD_GID
else
    # Create nix group if it doesn't exist
    groupadd -r nixbld
    NIXBLD_GID=$(getent group nixbld | cut -d: -f3)
fi

# Check if nixbld users already exist and find the starting UID
EXISTING_USERS=()
for i in $(seq 1 32); do
    if id "nixbld$i" >/dev/null 2>&1; then
        USER_UID=$(id -u "nixbld$i")
        EXISTING_USERS+=("nixbld$i:$USER_UID")
        if [ ${#EXISTING_USERS[@]} -eq 1 ]; then
            FIRST_UID=$USER_UID
            log "Found existing nixbld users starting with UID $FIRST_UID"
        fi
    fi
done

# If we found existing users, export the first UID for the installer
if [ ${#EXISTING_USERS[@]} -gt 0 ]; then
    export NIX_FIRST_BUILD_UID=$FIRST_UID
    log "Using existing nixbld users (${#EXISTING_USERS[@]} found)"
else
    # Create nix build users if they don't exist
    log "Creating nixbld users"
    for i in $(seq 1 10); do
        useradd -r -g nixbld -G nixbld -d /var/empty -s /sbin/nologin \
                -c "Nix build user $i" nixbld$i
    done
fi

# Create necessary directories
mkdir -p /nix
mkdir -p /etc/nix

# Download and install Nix
NIX_VERSION="2.24.10"  # Latest stable as of writing
curl -L https://releases.nixos.org/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}-x86_64-linux.tar.xz | tar -xJ

# Install Nix with the existing group ID and user UID
cd nix-${NIX_VERSION}-x86_64-linux
if [ -n "${NIX_FIRST_BUILD_UID:-}" ]; then
    NIX_BUILD_GROUP_ID=$NIXBLD_GID NIX_FIRST_BUILD_UID=$NIX_FIRST_BUILD_UID ./install --daemon --yes
else
    NIX_BUILD_GROUP_ID=$NIXBLD_GID ./install --daemon --yes
fi

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
if [ -d "/nix" ]; then
    chown -R root:nixbld /nix
    chmod 1775 /nix/store
fi

log "Setting up Nix channels"

# Setup default channel for all users (only if nix-channel exists)
if [ -f "/nix/var/nix/profiles/default/bin/nix-channel" ]; then
    /nix/var/nix/profiles/default/bin/nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
    /nix/var/nix/profiles/default/bin/nix-channel --update
else
    log "Warning: nix-channel not found, channels will need to be set up by users"
fi

log "Nix package manager installation completed"
