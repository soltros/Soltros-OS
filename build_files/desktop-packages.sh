#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing RPM packages"

log "Enable Copr repos"

COPR_REPOS=(
    pgdev/ghostty
    # Add any other COPR repos you need for greetd/gtkgreet if they're not in main repos
)
for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr enable "$repo"
done

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
    gnome-shell-extension-dash-to-panel
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

log "Disable Copr repos as we do not need it anymore"

for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr disable "$repo"
done