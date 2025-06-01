# Containerfile for SoltrOS: A Fedora-based, GNOME, gaming-optimized image
# Based on Universal Blue methodology

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

# Enable multilib repo and install required 32-bit libs for Steam
RUN sed -i 's/^#baseurl/baseurl/' /etc/yum.repos.d/fedora.repo && \
    sed -i 's/^#baseurl/baseurl/' /etc/yum.repos.d/fedora-updates.repo && \
    echo -e "include=\nmultilib_policy=all" >> /etc/dnf/dnf.conf

# Install default DNF apps from RPMFusion and elsewhere
RUN rpm-ostree install \
    gimp \
    vlc \
    heroic-games-launcher \
    mbpfan \
    lm_sensors \
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

# Install Flatpaks
COPY install-flatpaks.sh /tmp/install-flatpaks.sh
RUN bash /tmp/install-flatpaks.sh && rm /tmp/install-flatpaks.sh


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

# Add SoltrOS logo icons in multiple sizes
COPY soltros-logo.png /usr/share/icons/hicolor/128x128/apps/soltros.png
COPY soltros-logo.png /usr/share/icons/hicolor/256x256/apps/soltros.png
COPY soltros-logo.png /usr/share/icons/hicolor/512x512/apps/soltros.png
COPY soltros-logo.png /usr/share/pixmaps/soltros.png

# Add a desktop entry for SoltrOS branding
RUN echo "[Desktop Entry]
Name=SoltrOS
Comment=Custom Fedora-based GNOME OS by Soltros
Exec=gnome-control-center info
Icon=soltros
Type=Application
Categories=Settings;" > /usr/share/applications/soltros-about.desktop

# Show custom branding on terminal login screen
RUN echo -e '\n\e[1;36mWelcome to SoltrOS — powered by Fedora Silverblue\e[0m\n' > /etc/issue

# Update icon cache so GNOME recognizes custom icons
RUN gtk-update-icon-cache -f /usr/share/icons/hicolor


# GNOME customization: disable all extensions except Caffeine
RUN gsettings set org.gnome.shell disable-user-extensions true && \
    flatpak install -y flathub com.github.dhiebert.caffeine

# Set default GNOME session to vanilla (if applicable)
# (Assumes GNOME already installed via base)

# Clean up
RUN dnf clean all

LABEL org.opencontainers.image.title="SoltrOS" \
      org.opencontainers.image.description="Gaming-tuned, minimal Fedora-based GNOME image with Waterfox and RPMFusion apps"
