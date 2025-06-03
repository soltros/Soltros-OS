# SoltrOS base
FROM ghcr.io/ublue-os/silverblue-main

LABEL org.opencontainers.image.title="SoltrOS"
LABEL org.opencontainers.image.description="Vanilla GNOME, gaming-ready Fedora image with MacBook support"
LABEL org.opencontainers.image.vendor="Derrik"
LABEL org.opencontainers.image.version="42"

# Add in Flathub
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Setup Copr repos
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    mkdir -p /var/roothome && \
    dnf5 -y install dnf5-plugins && \
    for copr in \
        bazzite-org/bazzite \
        bazzite-org/bazzite-multilib \
        ublue-os/staging \
        ublue-os/packages \
        bazzite-org/LatencyFleX \
        bazzite-org/obs-vkcapture \
        ycollet/audinux \
        bazzite-org/rom-properties \
        bazzite-org/webapp-manager \
        hhd-dev/hhd \
        che/nerd-fonts \
        hikariknight/looking-glass-kvmfr \
        mavit/discover-overlay \
        rok/cdemu \
        lizardbyte/beta; \
    do \
        echo "Enabling copr: $copr"; \
        dnf5 -y copr enable $copr; \
        dnf5 -y config-manager setopt copr:copr.fedorainfracloud.org:${copr////:}.priority=98 ;\
    done && unset -v copr && \
    dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras} && \
    dnf5 -y config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo && \
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-steam.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-rar.repo && \
    dnf5 -y config-manager setopt "*bazzite*".priority=1 && \
    dnf5 -y config-manager setopt "*akmods*".priority=2 && \
    dnf5 -y config-manager setopt "*terra*".priority=3 "*terra*".exclude="nerd-fonts topgrade" && \
    dnf5 -y config-manager setopt "terra-mesa".enabled=true && \
    dnf5 -y config-manager setopt "terra-nvidia".enabled=false && \
    dnf5 -y config-manager setopt "*negativo17*".priority=4 "*negativo17*".exclude="mesa-* *xone*" && \
    dnf5 -y config-manager setopt "*rpmfusion*".priority=5 "*rpmfusion*".exclude="mesa-*" && \
    dnf5 -y config-manager setopt "*fedora*".exclude="mesa-* kernel-core-* kernel-modules-* kernel-uki-virt-*" && \
    dnf5 -y config-manager setopt "*staging*".exclude="scx-scheds kf6-* mesa* mutter* rpm-ostree* systemd* gnome-shell gnome-settings-daemon gnome-control-center gnome-software libadwaita tuned*" && \
    dnf5 clean all

# Install kernel (simplified - remove akmods references since they're not defined)
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y config-manager setopt "*rpmfusion*".enabled=0 && \
    dnf5 -y copr enable bieszczaders/kernel-cachyos-addons && \
    dnf5 -y install \
        scx-scheds && \
    dnf5 -y copr disable bieszczaders/kernel-cachyos-addons && \
    dnf5 -y swap --repo copr:copr.fedorainfracloud.org:bazzite-org:bazzite bootc bootc && \
    dnf5 clean all

# Setup firmware
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y swap atheros-firmware atheros-firmware-20250311-1$(rpm -E %{dist}) && \
    if [[ "${IMAGE_FLAVOR}" =~ "asus" ]]; then \
        dnf5 -y copr enable lukenukem/asus-linux && \
        dnf5 -y install \
            asusctl \
            asusctl-rog-gui && \
        dnf5 copr disable -y lukenukem/asus-linux \
    ; elif [[ "${IMAGE_FLAVOR}" == "surface" ]]; then \
        dnf5 -y config-manager addrepo --from-repofile=https://pkg.surfacelinux.com/fedora/linux-surface.repo && \
        dnf5 -y swap \
            --allowerasing \
            libwacom-data libwacom-surface-data && \
        dnf5 versionlock add \
            libwacom-surface-data && \
        dnf5 -y install \
            iptsd \
            libcamera \
            libcamera-tools \
            libcamera-gstreamer \
            libcamera-ipa \
            pipewire-plugin-libcamera && \
        dnf5 -y config-manager setopt "linux-surface".enabled=0 \
    ; fi && \
    dnf5 clean all

# Install patched packages
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    declare -A toswap=( \
        ["copr:copr.fedorainfracloud.org:bazzite-org:bazzite"]="wireplumber" \
        ["copr:copr.fedorainfracloud.org:bazzite-org:bazzite-multilib"]="pipewire bluez xorg-x11-server-Xwayland" \
        ["terra-extras"]="switcheroo-control" \
        ["terra-mesa"]="mesa-filesystem" \
        ["copr:copr.fedorainfracloud.org:ublue-os:staging"]="fwupd" \
    ) && \
    for repo in "${!toswap[@]}"; do \
        for package in ${toswap[$repo]}; do dnf5 -y swap --repo=$repo $package $package; done; \
    done && unset -v toswap repo package && \
    dnf5 versionlock add \
        pipewire \
        pipewire-alsa \
        pipewire-gstreamer \
        pipewire-jack-audio-connection-kit \
        pipewire-jack-audio-connection-kit-libs \
        pipewire-libs \
        pipewire-plugin-libcamera \
        pipewire-pulseaudio \
        pipewire-utils \
        wireplumber \
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
        fwupd-plugin-uefi-capsule-data && \
    dnf5 -y install --enable-repo="*rpmfusion*" --disable-repo="*fedora-multimedia*" \
        libaacs \
        libbdplus \
        libbluray \
        libbluray-utils && \
    dnf5 clean all

# Remove unneeded packages
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y remove \
        ublue-os-update-services \
        firefox \
        firefox-langpacks \
        htop && \
    dnf5 clean all

# Install new packages
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y install \
        twitter-twemoji-fonts \
        google-noto-sans-cjk-fonts \
        lato-fonts \
        fira-code-fonts \
        nerd-fonts \
        discover-overlay \
        sunshine \
        python3-pip \
        libadwaita \
        duperemove \
        cpulimit \
        sqlite \
        xwininfo \
        xrandr \
        compsize \
        ryzenadj \
        ddcutil \
        input-remapper \
        i2c-tools \
        lm_sensors \
        fw-ectool \
        fw-fanctrl \
        udica \
        ladspa-caps-plugins \
        ladspa-noise-suppression-for-voice \
        pipewire-module-filter-chain-sofa \
        python3-icoextract \
        tailscale \
        webapp-manager \
        btop \
        duf \
        fish \
        lshw \
        xdotool \
        wmctrl \
        libcec \
        yad \
        f3 \
        pulseaudio-utils \
        lzip \
        p7zip \
        p7zip-plugins \
        rar \
        libxcrypt-compat \
        vulkan-tools \
        extest.i686 \
        xwiimote-ng \
        fastfetch \
        glow \
        gum \
        vim \
        cockpit-networkmanager \
        cockpit-podman \
        cockpit-selinux \
        cockpit-system \
        cockpit-navigator \
        cockpit-storaged \
        topgrade \
        ydotool \
        stress-ng \
        snapper \
        btrfs-assistant \
        podman-compose \
        edk2-ovmf \
        qemu \
        libvirt \
        lsb_release \
        uupd \
        rocm-hip \
        rocm-opencl \
        rocm-clinfo \
        waydroid \
        cage \
        wlr-randr && \
    sed -i 's|uupd|& --disable-module-distrobox|' /usr/lib/systemd/system/uupd.service && \
    setcap 'cap_sys_admin+p' /usr/bin/sunshine-v* && \
    dnf5 -y --setopt=install_weak_deps=False install \
        rocm-hip \
        rocm-opencl \
        rocm-clinfo \
        rocm-smi && \
    dnf5 -y install \
        $(curl https://api.github.com/repos/bazzite-org/cicpoffs/releases/latest | jq -r '.assets[] | select(.name| test(".*rpm$")).browser_download_url') && \
    mkdir -p /etc/xdg/autostart && \
    sed -i~ -E 's/=.\$\(command -v (nft|ip6?tables-legacy).*/=/g' /usr/lib/waydroid/data/scripts/waydroid-net.sh && \
    sed -i 's/ --xdg-runtime=\\"${XDG_RUNTIME_DIR}\\"//g' /usr/bin/btrfs-assistant-launcher && \
    curl -Lo /usr/bin/installcab https://raw.githubusercontent.com/bazzite-org/steam-proton-mf-wmv/master/installcab.py && \
    chmod +x /usr/bin/installcab && \
    curl -Lo /usr/bin/install-mf-wmv https://github.com/bazzite-org/steam-proton-mf-wmv/blob/master/install-mf-wmv.sh && \
    chmod +x /usr/bin/install-mf-wmv && \
    curl -Lo /tmp/ls-iommu.tar.gz $(curl https://api.github.com/repos/HikariKnight/ls-iommu/releases/latest | jq -r '.assets[] | select(.name| test(".*x86_64.tar.gz$")).browser_download_url') && \
    mkdir -p /tmp/ls-iommu && \
    tar --no-same-owner --no-same-permissions --no-overwrite-dir -xvzf /tmp/ls-iommu.tar.gz -C /tmp/ls-iommu && \
    rm -f /tmp/ls-iommu.tar.gz && \
    cp -r /tmp/ls-iommu/ls-iommu /usr/bin/ && \
    curl -Lo /tmp/scopebuddy.tar.gz https://github.com/HikariKnight/ScopeBuddy/archive/refs/tags/$(curl https://api.github.com/repos/HikariKnight/scopebuddy/releases/latest | jq -r '.tag_name').tar.gz && \
    mkdir -p /tmp/scopebuddy && \
    tar --no-same-owner --no-same-permissions --no-overwrite-dir -xvzf /tmp/scopebuddy.tar.gz -C /tmp/scopebuddy && \
    rm -f /tmp/scopebuddy.tar.gz && \
    cp -r /tmp/scopebuddy/ScopeBuddy-*/bin/* /usr/bin/ && \
    dnf5 clean all

# Install Steam & Lutris, plus supporting packages
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 -y swap \
    --repo copr:copr.fedorainfracloud.org:bazzite-org:bazzite \
        ibus ibus && \
    dnf5 versionlock add \
        ibus && \
    dnf5 -y install \
        gamescope.x86_64 \
        gamescope-libs.x86_64 \
        gamescope-libs.i686 \
        gamescope-shaders \
        jupiter-sd-mounting-btrfs \
        umu-launcher \
        dbus-x11 \
        xdg-user-dirs \
        gobject-introspection \
        libFAudio.x86_64 \
        libFAudio.i686 \
        latencyflex-vulkan-layer \
        vkBasalt.x86_64 \
        vkBasalt.i686 \
        mangohud.x86_64 \
        mangohud.i686 \
        libobs_vkcapture.x86_64 \
        libobs_glcapture.x86_64 \
        libobs_vkcapture.i686 \
        libobs_glcapture.i686 \
        VK_hdr_layer && \
    dnf5 -y --setopt=install_weak_deps=False install \
        steam \
        lutris && \
    dnf5 -y remove \
        gamemode && \
    curl -Lo /tmp/latencyflex.tar.xz $(curl https://api.github.com/repos/ishitatsuyuki/LatencyFleX/releases/latest | jq -r '.assets[] | select(.name| test(".*.tar.xz$")).browser_download_url') && \
    mkdir -p /tmp/latencyflex && \
    tar --no-same-owner --no-same-permissions --no-overwrite-dir --strip-components 1 -xvf /tmp/latencyflex.tar.xz -C /tmp/latencyflex && \
    rm -f /tmp/latencyflex.tar.xz && \
    mkdir -p /usr/lib64/latencyflex && \
    cp -r /tmp/latencyflex/wine/usr/lib/wine/* /usr/lib64/latencyflex/ && \
    curl -Lo /usr/bin/latencyflex https://raw.githubusercontent.com/bazzite-org/LatencyFleX-Installer/main/install.sh && \
    chmod +x /usr/bin/latencyflex && \
    curl -Lo /usr/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/bin/winetricks && \
    dnf5 clean all

# ublue-os-media-automount-udev
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    dnf5 install -y --enable-repo=copr:copr.fedorainfracloud.org:ublue-os:packages \
        ublue-os-media-automount-udev && \
    { systemctl enable ublue-os-media-automount.service || true; } && \
    dnf5 clean all

# Install default DNF apps
RUN rpm-ostree install \
    gimp \
    vlc \
    heroic-games-launcher \
    mbpfan \
    fish \
    lm_sensors \
    tailscale \
    filezilla \
    telegram-desktop \
    discord \
    nextcloud-client \
    qbittorrent \
    thunderbird \
    papirus-icon-theme \
    goverlay

# Enable tailscaled to run on boot
RUN ln -s /usr/lib/systemd/system/tailscaled.service /etc/systemd/system/multi-user.target.wants/tailscaled.service

# Install Waterfox
ADD https://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/Fedora_41/x86_64/waterfox-6.5.6-1.21.x86_64.rpm /tmp/waterfox.rpm
RUN dnf install -y --nogpgcheck /tmp/waterfox.rpm && rm /tmp/waterfox.rpm

# Add SoltrOS icons
COPY soltros-logo.png /usr/share/icons/hicolor/128x128/apps/fedora-logo.png
COPY soltros-logo.png /usr/share/icons/hicolor/256x256/apps/fedora-logo.png
COPY soltros-logo.png /usr/share/icons/hicolor/512x512/apps/fedora-logo.png
COPY fedora-gdm-logo.png /usr/share/pixmaps/fedora-gdm-logo.png
COPY fedora_whitelogo_med.png /usr/share/pixmaps/fedora_whitelogo_med.png

# Add SoltrOS identity files
RUN curl -L https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/os-release -o /usr/lib/os-release

# Set MOTD
RUN curl -L https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/motd -o /etc/motd

# Set icon + theme defaults via dconf
RUN curl -L https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/00-soltros-settings -o /etc/dconf/db/local.d/00-soltros-settings && \
    dconf update

# Fetch flatpak install script into /etc/skel
RUN curl -L https://raw.githubusercontent.com/soltros/random-stuff/refs/heads/main/bash/flatpaks.sh \
  -o /etc/skel/install-flatpaks.sh && chmod +x /etc/skel/install-flatpaks.sh
    
# Add terminal branding
RUN echo -e '\n\e[1;36mWelcome to SoltrOS — powered by Fedora Silverblue\e[0m\n' > /etc/issue

# Update icon cache
RUN gtk-update-icon-cache -f /usr/share/icons/hicolor

# Clean up
RUN dnf clean all

LABEL org.opencontainers.image.title="SoltrOS" \
      org.opencontainers.image.description="Gaming-tuned, minimal Fedora-based GNOME image with Waterfox and RPMFusion apps"
