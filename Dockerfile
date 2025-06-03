# SoltrOS base
FROM ghcr.io/ublue-os/silverblue-main

LABEL org.opencontainers.image.title="SoltrOS"
LABEL org.opencontainers.image.description="Vanilla GNOME, gaming-ready Fedora image with MacBook support"
LABEL org.opencontainers.image.vendor="Derrik"
LABEL org.opencontainers.image.version="42"

# Add in Flathub
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Add RPM Fusion free/nonfree
RUN rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Add the Terra repository
ADD https://terra.fyralabs.com/terra.repo /etc/yum.repos.d/terra.repo

# Add the Tailscale repository
COPY tailscale.repo /etc/yum.repos.d/tailscale.repo

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

# Add SoltrOS icons (Note: these files need to exist in your build context)
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
