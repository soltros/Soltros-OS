# Stage 0: Import akmods from official image
FROM ghcr.io/ublue-os/akmods:release as akmods

# Stage 1: SoltrOS base
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

# Install default DNF apps
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

# Remove Firefox
RUN rpm-ostree override remove firefox

# Install Waterfox
ADD https://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/Fedora_41/x86_64/waterfox-6.5.6-1.21.x86_64.rpm /tmp/waterfox.rpm
RUN rpm-ostree install --nogpgcheck /tmp/waterfox.rpm && rm /tmp/waterfox.rpm

# ✅ Copy over kmods from akmods stage (defined at top)
COPY --from=akmods /rpms /tmp/akmods

RUN dnf install -y \
    /tmp/akmods/kmods/*kvmfr*.rpm \
    /tmp/akmods/kmods/*xone*.rpm \
    /tmp/akmods/kmods/*openrazer*.rpm \
    /tmp/akmods/kmods/*wl*.rpm \
    /tmp/akmods/kmods/*framework-laptop*.rpm \
    /tmp/akmods/kmods/*gcadapter_oc*.rpm \
    /tmp/akmods/kmods/*zenergy*.rpm \
    /tmp/akmods/kmods/*gpd-fan*.rpm \
    /tmp/akmods/kmods/*ayaneo-platform*.rpm \
    /tmp/akmods/kmods/*ayn-platform*.rpm \
    /tmp/akmods/kmods/*bmi260*.rpm \
    /tmp/akmods/kmods/*ryzen-smu*.rpm && \
    rm -rf /tmp/akmods

# Add SoltrOS icons
COPY soltros-logo.png /usr/share/icons/hicolor/128x128/apps/soltros.png
COPY soltros-logo.png /usr/share/icons/hicolor/256x256/apps/soltros.png
COPY soltros-logo.png /usr/share/icons/hicolor/512x512/apps/soltros.png
COPY soltros-logo.png /usr/share/pixmaps/soltros.png

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

