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

log "Creating snap maintenance script for SoltrOS"
# Create the script that will maintain snap setup on boot
mkdir -p /opt/soltros-snap
cat > /opt/soltros-snap/snapd-setup.sh << 'EOF'
#!/bin/bash
# SoltrOS Snap Setup Script - maintains snap compatibility on boot
# Based on snapd-in-Silverblue solution

bindnotok=0
symlinknok=0

# Check if bind mount in /home is already applied
checkbindmount(){
    if [ -d '/home' ] && [ ! -L '/home' ]
    then echo "bindmount of /home ok"
    else bindnotok=1 && echo "bindmount of /home not ok"
    fi
}

# Replace symlink in /home with bind mount
bindmounthome(){
    if [ -L '/home' ]
    then echo "symlink /home will be replaced with bind mount from /var/home"
    else echo "bind mount will be created from /var/home to /home"
    fi

    rm -f /home | systemd-cat -t soltros-snap.service -p info
    mkdir -p /home
    mount --bind /var/home /home
}

# Replace /var/home to /home in /etc/passwd
passwdhome(){
    if grep -Fq ':/var/home' /etc/passwd
    then
        cp /etc/passwd /etc/passwd.backup
        echo "backup of /etc/passwd created"
        sed -i 's|:/var/home|:/home|' /etc/passwd
        echo "/etc/passwd edited: /var/home replaced with /home"
    else
        echo "/etc/passwd ok"
    fi
}

# Check if symlink in /snap exists
checksymlink(){
    if [[ $(readlink "/snap") == "/var/lib/snapd/snap" ]]
    then echo 'snap symlink ok'
    else symlinknok=1 && echo 'snap symlink not ok'
    fi
}

# Create symlink in /snap
symlinksnap(){
    echo "creating /var/lib/snapd/snap symlink in /snap"
    ln -sf '/var/lib/snapd/snap' '/snap' | systemd-cat -t soltros-snap.service -p info
    checksymlink
}

# Check current state
checkbindmount
checksymlink
passwdhome

# Only unlock / if changes are needed
if (( $bindnotok + $symlinknok ))
then
    chattr -i /
    if (( ${bindnotok} )); then bindmounthome; fi
    if (( ${symlinknok} )); then symlinksnap; fi
    chattr +i /
fi
EOF

chmod +x /opt/soltros-snap/snapd-setup.sh

log "Creating systemd service for snap maintenance"
cat > /etc/systemd/system/soltros-snap.service << 'EOF'
[Unit]
Description=SoltrOS Snap Setup - Maintain snap compatibility
Before=snapd.service
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/opt/soltros-snap/snapd-setup.sh
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
