# Set base image and tag
#ARG BASE_IMAGE=ghcr.io/ublue-os/base-main
ARG BASE_IMAGE=docker.io/fedora
ARG TAG_VERSION=latest

# Stage 1: context for scripts (not included in final image)
FROM ${BASE_IMAGE}:${TAG_VERSION} AS ctx
COPY build_files/ /ctx/
COPY soltros.pub /ctx/soltros.pub

# Stage 2: final image
FROM ${BASE_IMAGE}:${TAG_VERSION} AS soltros

LABEL org.opencontainers.image.title="SoltrOS" \
    org.opencontainers.image.description="Gaming-ready Universal Blue image with MacBook support" \
    org.opencontainers.image.vendor="Derrik" \
    org.opencontainers.image.version="42"

# Copy static system configuration and branding
COPY system_files/etc /etc
COPY system_files/usr/share /usr/share
COPY repo_files/tailscale.repo /etc/yum.repos.d/tailscale.repo
COPY resources/soltros-gdm.png /usr/share/pixmaps/fedora-gdm-logo.png
COPY resources/soltros-watermark.png /usr/share/plymouth/themes/spinner/watermark.png
# Create necessary directories for shell configurations
RUN mkdir -p /etc/profile.d /etc/fish/conf.d

# Create Greetd user
RUN useradd -r -s /sbin/nologin -d /var/lib/greeter -m greeter

# Add RPM Fusion repos and VirtualBo
RUN dnf5 install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Enable Tailscale
RUN ln -sf /usr/lib/systemd/system/tailscaled.service /etc/systemd/system/multi-user.target.wants/tailscaled.service

# Add Terra repo separately with better error handling
RUN for i in {1..3}; do \
    curl --retry 3 --retry-delay 5 -Lo /etc/yum.repos.d/terra.repo https://terra.fyralabs.com/terra.repo && \
    break || sleep 10; \
    done

# Set identity and system branding with better error handling
RUN for i in {1..3}; do \
    curl --retry 3 --retry-delay 5 -Lo /usr/lib/os-release https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/os-release && \
    break || sleep 10; \
    done && \
    for i in {1..3}; do \
    curl --retry 3 --retry-delay 5 -Lo /etc/motd https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/motd && \
    break || sleep 10; \
    done && \
    for i in {1..3}; do \
    curl --retry 3 --retry-delay 5 -Lo /etc/dconf/db/local.d/00-soltros-settings https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/00-soltros-settings && \
    break || sleep 10; \
    done && \
    dconf update && \
    echo -e '\n\e[1;36mWelcome to SoltrOS — powered by Universal Blue\e[0m\n' > /etc/issue && \
    gtk-update-icon-cache -f /usr/share/icons/hicolor

# Enable podman socket and thermal management services
RUN dnf install -y podman thermald mbpfan && \
    systemctl enable podman.socket thermald mbpfan

RUN set -eou pipefail && \
    echo "=== Enable podman socket ===" && \
    systemctl enable podman.socket && \
    echo "=== Enable thermal management services ===" && \
    systemctl enable thermald

# Installing RPM packages
RUN set -eou pipefail && \
    echo "=== Installing RPM packages ===" && \
    echo "=== Enable Copr repos ===" && \
    dnf5 -y copr enable pgdev/ghostty && \
    \
    echo "=== Install layered applications ===" && \
    dnf5 install --setopt=install_weak_deps=False --nogpgcheck -y \
        fish \
        tailscale \
        ptyxis \
        papirus-icon-theme \
        lm_sensors \
        udisks2 \
        udiskie \
        gimp \
        pipewire \
        pipewire-pulse \
        wireplumber \
        starship \
        pipewire-alsa \
        deja-dup \
        playerctl \
        linux-firmware \
        pipewire-gstreamer \
        pipewire-jack-audio-connection-kit \
        pipewire-jack-audio-connection-kit-libs \
        pipewire-libs \
        pipewire-plugin-libcamera \
        pipewire-pulseaudio \
        pipewire-utils \
        wireplumber-libs \
        bluez \
        bluez-cups \
        bluez-libs \
        bluez-obexd \
        xorg-x11-server-Xwayland \
        switcheroo-control \
        mesa-dri-drivers \
        mesa-filesystem \
        mesa-libEGL \
        mesa-libGL \
        mesa-libgbm \
        mesa-va-drivers \
        mesa-vulkan-drivers \
        fwupd \
        fwupd-plugin-flashrom \
        fwupd-plugin-modem-manager \
        fwupd-plugin-uefi-capsule-data \
        greetd \
        greetd-gtkgreet \
        cage \
        gamemode \
        gamemode-devel \
        mangohud \
        goverlay \
        corectrl \
        steam-devices \
        mbpfan \
        thermald \
        btop \
        ripgrep \
        fd-find \
        git-delta \
        nvtop \
        powertop \
        smartmontools \
        usbutils \
        pciutils \
        buildah \
        skopeo \
        podman-compose \
        iperf3 \
        nmap \
        wireguard-tools \
        exfatprogs \
        ntfs-3g \
        btrfs-progs \
        gvfs \
        gvfs-smb \
        gvfs-fuse \
        gvfs-mtp \
        gvfs-gphoto2 \
        gvfs-archive \
        gvfs-afp \
        gvfs-nfs \
        samba-client \
        cifs-utils && \
    \
    echo "=== Disable Copr repos as we do not need it anymore ===" && \
    dnf5 -y copr disable pgdev/ghostty && \
    \
    echo "=== Enabling various services ===" && \
    (systemctl enable pipewire.service || true) && \
    (systemctl enable pipewire-pulse.service || true) && \
    (systemctl enable wireplumber.service || true) && \
    \
    echo "=== Installing Papirus Folders Utility ===" && \
    wget -qO- https://git.io/papirus-folders-install | sh && \
    \
    echo "=== Removing Firefox in favor of Waterfox ===" && \
    (dnf5 remove -y firefox firefox-* || true) && \
    \
    echo "=== Removing Plasma Discover ===" && \
    (dnf5 remove -y plasma-discover* || true)

    # Apply gaming optimizations
RUN set -euo pipefail && \
    echo "=== Applying gaming optimizations ===" && \
    echo "=== Setting up gaming-specific sysctl parameters ===" && \
    cat > /etc/sysctl.d/99-gaming.conf << 'EOF' && \
# Gaming optimizations for better performance
# Increase memory map areas for games (especially needed for newer games)
vm.max_map_count = 2147483642
# Increase file descriptor limits for gaming applications
fs.file-max = 2097152
# Network optimizations for online gaming
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
# Reduce swappiness for gaming performance (keep things in RAM)
vm.swappiness = 1
# Optimize dirty page writeback for gaming workloads
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF
    \
    echo "=== Setting up gaming udev rules for controller access ===" && \
    cat > /etc/udev/rules.d/99-gaming-devices.rules << 'EOF' && \
# Gaming controller access rules
# PlayStation controllers (PS3, PS4, PS5)
SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*054c*", MODE="0666", TAG+="uaccess"
# Xbox controllers (Xbox One, Series X/S)
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*045e*", MODE="0666", TAG+="uaccess"
# Nintendo Switch Pro Controller
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*057e*", MODE="0666", TAG+="uaccess"
# Steam Controller
SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*28de*", MODE="0666", TAG+="uaccess"
# 8BitDo controllers
SUBSYSTEM=="usb", ATTRS{idVendor}=="2dc8", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*2dc8*", MODE="0666", TAG+="uaccess"
EOF
    \
    echo "=== Setting up gaming-specific environment variables ===" && \
    cat > /etc/profile.d/gaming.sh << 'EOF' && \
# Gaming environment optimizations
# Enable Steam native runtime by default (better compatibility)
export STEAM_RUNTIME_PREFER_HOST_LIBRARIES=0
# Enable MangoHud for all Vulkan applications (if installed)
# export MANGOHUD=1
# Enable gamemode for supported applications
# export LD_PRELOAD="libgamemode.so.0:$LD_PRELOAD"
# Optimize for AMD GPUs (uncomment if using AMD)
# export RADV_PERFTEST=aco,llvm
# export AMD_VULKAN_ICD=RADV
# Optimize for NVIDIA GPUs (uncomment if using NVIDIA)
# export __GL_THREADED_OPTIMIZATIONS=1
# export __GL_SHADER_DISK_CACHE=1
EOF
    \
    echo "=== Setting up gaming-specific modules to load ===" && \
    cat > /etc/modules-load.d/gaming.conf << 'EOF' && \
# Gaming-related kernel modules
# Xbox controller support
xpad
# General HID support for gaming devices
uinput
EOF
    \
    echo "=== Setting up CPU governor optimization for gaming ===" && \
    cat > /etc/tmpfiles.d/gaming-cpu.conf << 'EOF' && \
# Set CPU governor to performance mode for gaming
# This will be applied at boot
w /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor - - - - performance
EOF
    \
    echo "=== Gaming optimizations applied successfully ==="

# SoltrOS: Container Signing Setup
# Configures sigstore signing trust for ghcr.io/soltros containers
COPY soltros.pub /tmp/soltros.pub
RUN set -eou pipefail && \
    NAMESPACE="soltros" && \
    PUBKEY="/etc/pki/containers/${NAMESPACE}.pub" && \
    POLICY="/etc/containers/policy.json" && \
    REGISTRY="ghcr.io/${NAMESPACE}" && \
    \
    echo "=== Preparing directories ===" && \
    mkdir -p /etc/containers && \
    mkdir -p /etc/pki/containers && \
    mkdir -p /etc/containers/registries.d/ && \
    \
    echo "=== Setting up policy.json for sigstore ===" && \
    if [ -f /usr/etc/containers/policy.json ]; then \
        cp /usr/etc/containers/policy.json "$POLICY"; \
    elif [ ! -f "$POLICY" ]; then \
        cat > "$POLICY" << 'EOF'
{
 "default": [
 {
 "type": "insecureAcceptAnything"
 }
 ],
 "transports": {
 "docker-daemon": {
 "": [
 {
 "type": "insecureAcceptAnything"
 }
 ]
 },
 "docker": {}
 }
}
EOF
    fi && \
    \
    jq ".transports.docker[\"${REGISTRY}\"] = [{
\"type\": \"sigstoreSigned\",
\"keyPaths\": [\"${PUBKEY}\"],
\"signedIdentity\": {
\"type\": \"matchRepository\"
 }
}]" "$POLICY" > /tmp/policy.json && mv /tmp/policy.json "$POLICY" && \
    \
    echo "=== Copying cosign public key ===" && \
    cp /tmp/soltros.pub "$PUBKEY" && \
    \
    echo "=== Creating registry policy YAML ===" && \
    cat > "/etc/containers/registries.d/${NAMESPACE}.yaml" << EOF && \
docker:
 ${REGISTRY}:
 use-sigstore-attachments: true
EOF
    \
    echo "=== Signing policy setup complete for $REGISTRY ==="    

# Install latest Waterfox browser
RUN set -euo pipefail && \
    echo "=== Installing latest Waterfox browser ===" && \
    echo "=== Fetching latest Waterfox version from GitHub API ===" && \
    LATEST_VERSION=$(curl -s https://api.github.com/repos/BrowserWorks/Waterfox/releases/latest | grep '"tag_name"' | cut -d '"' -f 4) && \
    \
    if [ -z "$LATEST_VERSION" ]; then \
        echo "Error: Failed to fetch latest version from GitHub API, falling back to manual installation" && \
        exit 1; \
    fi && \
    \
    echo "Latest Waterfox version: $LATEST_VERSION" && \
    WATERFOX_URL="https://cdn1.waterfox.net/waterfox/releases/${LATEST_VERSION}/Linux_x86_64/waterfox-${LATEST_VERSION}.tar.bz2" && \
    ARCHIVE="/tmp/waterfox-${LATEST_VERSION}.tar.bz2" && \
    INSTALL_DIR="/usr/share/soltros/waterfox" && \
    BIN_LINK="/usr/share/soltros/waterfox/waterfox" && \
    DESKTOP_FILE="/usr/share/applications/waterfox.desktop" && \
    \
    echo "=== Downloading Waterfox ${LATEST_VERSION} ===" && \
    mkdir -p "$INSTALL_DIR" && \
    curl --retry 3 --retry-delay 5 \
        --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" \
        -L -o "$ARCHIVE" \
        "$WATERFOX_URL" && \
    \
    if [ ! -f "$ARCHIVE" ]; then \
        echo "Error: Failed to download Waterfox archive" && \
        exit 1; \
    fi && \
    \
    echo "=== Extracting Waterfox archive ===" && \
    tar -xf "$ARCHIVE" -C "$INSTALL_DIR" --strip-components=1 && \
    \
    echo "=== Creating desktop launcher ===" && \
    cat > "$DESKTOP_FILE" <<EOF && \
[Desktop Entry]
Name=Waterfox
Comment=Privacy-focused web browser
Exec=$BIN_LINK %u
Icon=$INSTALL_DIR/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
StartupWMClass=Waterfox
EOF
    chmod +x "$DESKTOP_FILE" && \
    \
    echo "=== Cleaning up temporary files ===" && \
    rm -f "$ARCHIVE" && \
    \
    echo "=== Waterfox ${LATEST_VERSION} installation complete ===" && \
    echo "Installed to: $INSTALL_DIR" && \
    echo "Desktop file: $DESKTOP_FILE" && \
    echo "Command available: waterfox"

# Essential cleanup for bootc containers
RUN set -euo pipefail && \
    echo "=== Starting system cleanup ===" && \
    dnf5 clean all && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /var/cache/* && \
    rm -rf /var/log/* && \
    rm -rf /var/lib/dnf/repos/* && \
    rm -rf /usr/etc && \
    if [ -d /var/run ] && [ ! -L /var/run ]; then \
        echo "=== Fixing /var/run symlink ===" && \
        rm -rf /var/run && \
        ln -sf /run /var/run; \
    fi && \
    mkdir -p /tmp && chmod 1777 /tmp && \
    mkdir -p /var/tmp && chmod 1777 /var/tmp && \
    mkdir -p /var/cache && \
    mkdir -p /var/log && \
    echo "=== Cleanup completed ==="