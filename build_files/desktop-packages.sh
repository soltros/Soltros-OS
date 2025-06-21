#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing RPM packages"

log "Install layered applications"

# Layered Applications
LAYERED_PACKAGES=(
    # Core system
    fish
    tailscale
    ptyxis
    papirus-icon-theme
    lm_sensors
    udisks2
    udiskie
    gimp
    pipewire
    pipewire-pulse
    wireplumber
    starship
    pipewire-alsa
    deja-dup
    playerctl
    linux-firmware
    pipewire-alsa 
    pipewire-gstreamer
    pipewire-jack-audio-connection-kit
    pipewire-jack-audio-connection-kit-libs
    pipewire-libs
    pipewire-plugin-libcamera 
    pipewire-pulseaudio
    pipewire-utils
    wireplumber
    wireplumber-libs
    bluez
    bluez-cups
    bluez-libs
    bluez-obexd
    xorg-x11-server-Xwayland
    switcheroo-control
    mesa-dri-drivers
    mesa-filesystem
    mesa-libEGL
    mesa-libGL
    mesa-libgbm
    mesa-va-drivers
    mesa-vulkan-drivers
    fwupd
    fwupd-plugin-flashrom
    fwupd-plugin-modem-manager
    fwupd-plugin-uefi-capsule-data
    
    # Display manager and desktop groups (installed via group install elsewhere)
    greetd
    greetd-gtkgreet
    cage
    
    # Gaming & performance
    gamemode
    gamemode-devel
    mangohud
    goverlay
    corectrl
    steam-devices
    
    # MacBook thermal management
    mbpfan
    thermald
    
    # Essential CLI tools
    btop
    ripgrep
    fd-find
    git-delta
    
    # System monitoring & hardware
    nvtop
    powertop
    smartmontools
    usbutils
    pciutils
    
    # Development & container tools
    buildah
    skopeo
    podman-compose
    
    # Network tools
    iperf3
    nmap
    wireguard-tools
    
    # File system support
    exfatprogs
    ntfs-3g
    btrfs-progs
    
    # GVFS and network file system support
    gvfs
    gvfs-smb
    gvfs-fuse
    gvfs-mtp
    gvfs-gphoto2
    gvfs-archive
    gvfs-afp
    gvfs-nfs
    samba-client
    cifs-utils
    
    # Multimedia/audio
    pipewire-utils
    wireplumber
)

dnf5 install --setopt=install_weak_deps=False --nogpgcheck -y "${LAYERED_PACKAGES[@]}"

#Enabling various services
systemctl enable pipewire.service || true
systemctl enable pipewire-pulse.service || true
systemctl enable wireplumber.service || true

# Papirus Folders Utility
wget -qO- https://git.io/papirus-folders-install | sh

# Remove Firefox to replace with Waterfox
log "Removing Firefox in favor of Waterfox"
dnf5 remove -y firefox firefox-* || true

# Remove Plasma Discover from base image
log "Removing Plasma Discover"
dnf5 remove -y plasma-discover* || true