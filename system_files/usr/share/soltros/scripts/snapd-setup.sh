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
