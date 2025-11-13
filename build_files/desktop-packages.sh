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
    zsh
    tailscale
    papirus-icon-theme
    papirus-icon-theme-dark
    papirus-icon-theme-light
    materia*
    kvantum
    qt5-qtgraphicaleffects
    lm_sensors
    udisks2
    udiskie
    gimp
    pipewire
    pipewire-pulse
    wireplumber
    nebula
    dbus-tools
    alsa-utils
    syslinux
    pipewire-alsa
    deja-dup
    playerctl
    guestmount
    libguestfs-tools
    linux-firmware*
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
    libvirtd

    #DM
    greetd
    tuigreet

    #Hyprland/Hyprvibe components
    hyprland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    polkit-kde
    qt6ct
    waybar
    hyprland-qtutils
    wofi
    dunst
    hyprpaper
    hyprlock
    hypridle
    wl-clipboard
    cliphist
    grim
    slurp
    pipewire
    wireplumber
    pipewire-alsa
    pipewire-pulseaudio
    pipewire-jack-audio-connection-kit
    pavucontrol
    playerctl
    brightnessctl
    ddcutil
    dolphin
    kio-extras
    kio-fuse
    kio-admin
    ark
    udisks2
    gvfs
    glib-networking
    NetworkManager
    network-manager-applet
    alacritty
    jq
    curl
    lm_sensors
    htop
    jetbrains-mono-fonts
    
    # Gaming & performance
    gamemode
    gamemode-devel
    mangohud
    goverlay
    corectrl
    steam-devices
    gamescope
    gamescope-session
    gamescope-session-steam
    
    # MacBook thermal management
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
    virt-manager
    gnome-boxes
    gnome-tweaks
    
    # Multimedia/audio
    pipewire-utils
    wireplumber

    # Desktop utilities
    wlogout
    swayidle
    swaylock
    qt5-qtstyleplugins
    qt6-qtwayland
    qt5-qtwayland

    # Archive support
    p7zip
    p7zip-plugins
    unrar

    # Modern CLI tools
    fastfetch
    eza
    bat
    tldr

    # Multimedia applications
    mpv
    imv
    easyeffects
    ffmpeg
    ffmpeg-libs

    # Fonts
    google-noto-emoji-fonts
    liberation-fonts
    fira-code-fonts

    # Wayland utilities
    wlsunset
    wtype
    kanshi

    # Security & utilities
    keepassxc

    # Development
    neovim
)

dnf5 install --setopt=install_weak_deps=False --nogpgcheck --allowerasing --skip-broken -y "${LAYERED_PACKAGES[@]}"

#Enabling various services
systemctl enable pipewire.service || true
systemctl enable pipewire-pulse.service || true
systemctl enable wireplumber.service || true

# Remove Firefox to replace with Waterfox
log "Removing Firefox in favor of Waterfox"
dnf5 remove -y firefox firefox-* || true
