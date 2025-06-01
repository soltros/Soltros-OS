FROM ghcr.io/ublue-os/silverblue-main

# Containerfile for SoltrOS: A Fedora-based, GNOME, gaming-optimized image
# Based on Universal Blue methodology

FROM ghcr.io/ublue-os/bazzite:fedora-42

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


# Install default DNF apps from RPMFusion and elsewhere
RUN rpm-ostree install \
    steam \
    gimp \
    vlc \
    heroic-launcher \
    tailscale \
    filezilla \
    telegram-desktop \
    discord \
    nextcloud-client \
    qbittorrent \
    thunderbird \
    gamemode \
    mangohud \
    goverlay

# Enable tailscaled to run on boot
RUN ln -s /usr/lib/systemd/system/tailscaled.service /etc/systemd/system/multi-user.target.wants/tailscaled.service

# Create scripts directory
RUN mkdir -p /opt/scripts

# Copy post-install Flatpak script
COPY install-flatpaks.sh /opt/scripts/install-flatpaks.sh

# Make script executable
RUN chmod +x /opt/scripts/install-flatpaks.sh

# Remove Firefox (comes with base)
RUN rpm-ostree override remove firefox

# Install Waterfox manually
RUN curl -L "https://cdn1.waterfox.net/waterfox/releases/6.5.9/Linux_x86_64/waterfox-6.5.9.tar.bz2" -o /tmp/waterfox.tar.bz2 && \
    mkdir -p /opt/waterfox && \
    tar -xjf /tmp/waterfox.tar.bz2 -C /opt/waterfox --strip-components=1 && \
    rm /tmp/waterfox.tar.bz2 && \
    ln -s /opt/waterfox/waterfox /usr/local/bin/waterfox

# Add Waterfox launcher
RUN mkdir -p /usr/share/applications && \
    echo "[Desktop Entry]
Name=Waterfox G6
Exec=/opt/waterfox/waterfox %u
Icon=waterfox
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true" > /usr/share/applications/waterfox.desktop && \
    curl -L "https://cdn1.waterfox.net/img/icons/waterfox-icon.png" \
      -o /usr/share/icons/hicolor/128x128/apps/waterfox.png

# Install akmods group from Bazzite common and extra (excluding v4l2loopback and obs)
COPY --from=ghcr.io/ublue-os/akmods:bazzite / /tmp/akmods
RUN dnf install -y \
    /tmp/akmods/rpms/kmods/*kvmfr*.rpm \
    /tmp/akmods/rpms/kmods/*xone*.rpm \
    /tmp/akmods/rpms/kmods/*openrazer*.rpm \
    /tmp/akmods/rpms/kmods/*wl*.rpm \
    /tmp/akmods/rpms/kmods/*framework-laptop*.rpm \
    /tmp/akmods/rpms/kmods/*gcadapter_oc*.rpm \
    /tmp/akmods/rpms/kmods/*zenergy*.rpm \
    /tmp/akmods/rpms/kmods/*gpd-fan*.rpm \
    /tmp/akmods/rpms/kmods/*ayaneo-platform*.rpm \
    /tmp/akmods/rpms/kmods/*ayn-platform*.rpm \
    /tmp/akmods/rpms/kmods/*bmi260*.rpm \
    /tmp/akmods/rpms/kmods/*ryzen-smu*.rpm && \
    rm -rf /tmp/akmods

# Set branding/logo if needed later
# (customizations/logos would be added in /usr/share/icons or /etc/issue if desired)

# GNOME customization: disable all extensions except Caffeine
RUN gsettings set org.gnome.shell disable-user-extensions true && \
    flatpak install -y flathub com.github.dhiebert.caffeine

# Set default GNOME session to vanilla (if applicable)
# (Assumes GNOME already installed via base)

# Clean up
RUN dnf clean all

LABEL org.opencontainers.image.title="SoltrOS" \
      org.opencontainers.image.description="Gaming-tuned, minimal Fedora-based GNOME image with Waterfox and RPMFusion apps"
