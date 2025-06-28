#!/usr/bin/bash
set -euo pipefail

log() {
    echo "=== $* ==="
}

log "Installing Bazzite gaming package stack"

# Core gaming packages from Bazzite: Gaming launchers, runtimes, gamescope compositor, performance tools, audio compatibility, graphics enhancement layers, and OBS capture support
dnf5 -y install \
    steam \
    lutris \
    umu-launcher \
    gamescope.x86_64 \
    gamescope-libs.x86_64 \
    gamescope-libs.i686 \
    gamescope-shaders \
    gamemode \
    mangohud.x86_64 \
    mangohud.i686 \
    libFAudio.x86_64 \
    libFAudio.i686 \
    latencyflex-vulkan-layer \
    vkBasalt.x86_64 \
    vkBasalt.i686 \
    VK_hdr_layer \
    libobs_vkcapture.x86_64 \
    libobs_glcapture.x86_64 \
    libobs_vkcapture.i686 \
    libobs_glcapture.i686

# Install gaming-optimized audio stack from Bazzite repos
dnf5 -y swap \
    --repo copr:copr.fedorainfracloud.org:bazzite-org:bazzite-multilib \
    pipewire pipewire

dnf5 -y swap \
    --repo copr:copr.fedorainfracloud.org:bazzite-org:bazzite \
    wireplumber wireplumber

# Lock these packages to prevent unwanted updates
dnf5 versionlock add \
    pipewire \
    pipewire-alsa \
    pipewire-gstreamer \
    pipewire-jack-audio-connection-kit \
    pipewire-libs \
    pipewire-pulseaudio \
    wireplumber

# Apply Bazzite's gaming kernel parameters
cat > /etc/sysctl.d/99-bazzite-gaming.conf << 'EOF'
# Bazzite gaming optimizations
vm.max_map_count = 2147483642
fs.file-max = 2097152
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
vm.swappiness = 1
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

# Setup gaming controller udev rules (from Bazzite)
cat > /etc/udev/rules.d/99-bazzite-gaming.rules << 'EOF'
# Gaming controller access rules from Bazzite

# PlayStation controllers
SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*054c*", MODE="0666", TAG+="uaccess"

# Xbox controllers
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*045e*", MODE="0666", TAG+="uaccess"

# Nintendo Switch Pro Controller
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", MODE="0666", TAG+="uaccess"

# Steam Controller
SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0666", TAG+="uaccess"

# 8BitDo controllers
SUBSYSTEM=="usb", ATTRS{idVendor}=="2dc8", MODE="0666", TAG+="uaccess"
EOF

log "Bazzite gaming packages and optimizations installed"