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
    fish \
    lm_sensors \
    tailscale \
    filezilla \
    telegram-desktop \
    discord \
    nextcloud-client \
    qbittorrent \
    thunderbird \
    gamemode \
    papirus-icon-theme \
    mangohud \
    goverlay

# Enable tailscaled to run on boot
RUN ln -s /usr/lib/systemd/system/tailscaled.service /etc/systemd/system/multi-user.target.wants/tailscaled.service

# Remove Firefox
RUN rpm-ostree override remove firefox firefox-langpacks

# Install Waterfox
ADD https://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/Fedora_41/x86_64/waterfox-6.5.6-1.21.x86_64.rpm /tmp/waterfox.rpm
RUN dnf install -y --nogpgcheck /tmp/waterfox.rpm && rm /tmp/waterfox.rpm

# Add the COPR repo for UBlue Akmods
ADD https://copr.fedorainfracloud.org/coprs/ublue-os/akmods/repo/fedora-42/ublue-os-akmods-fedora-42.repo /etc/yum.repos.d/ublue-os-akmods.repo

# Install selected kmods from the repo
#RUN dnf install -y \
#    kmod-kvmfr \
#    openrazer-kmod \
##    kmod-wl \
#    framework-laptop-kmod \
#    gcadapter_oc-kmod \
#    zenergy-kmod \
#    gpd-fan-kmod \
#    ayaneo-platform-kmod \
#    ayn-platform-kmod \
##    bmi260-kmod \
#    ryzen-smu-kmod && \
#    dnf clean all

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
  
### Steam Spec
# Enable multilib and install 32-bit compatibility libraries
RUN echo -e "[multilib]\nname=Fedora \$releasever - Multilib\nbaseurl=https://download.fedoraproject.org/pub/fedora/linux/releases/\$releasever/Everything/\$basearch/os/\n        enabled=1\ngpgcheck=1\ngpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-\$releasever-\$basearch" > /etc/yum.repos.d/fedora-multilib.repo

# Install base tools and RPMFusion
RUN dnf install git rpm-build dnf-utils glibc.i686 libstdc++.i686 \
    libva.i686 libva-utils.i686 libvdpau.i686 \
    mesa-libEGL.i686 mesa-libGL.i686 mesa-dri-drivers.i686

# Optional: Add NVIDIA support (enable akmods again when ready)
# RUN rpm-ostree install xorg-x11-drv-nvidia xorg-x11-drv-nvidia-libs.i686 akmod-nvidia

# Clone RPMFusion Steam repo and build native RPM
WORKDIR /root
RUN git clone --depth=1 https://github.com/rpmfusion/steam.git steam-rpm \
 && mkdir -p rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS} \
 && cp steam-rpm/*.spec rpmbuild/SPECS/ \
 && cp steam-rpm/* rpmbuild/SOURCES/ || true \
 && cd rpmbuild/SPECS && dnf builddep -y steam.spec \
 && rpmbuild -ba steam.spec

# Install the built Steam RPM
RUN dnf install /root/rpmbuild/RPMS/x86_64/steam-*.rpm

# Clean up build files
RUN rm -rf /root/steam-rpm /root/rpmbuild

# Set environment variable for better desktop behavior
ENV STEAM_FORCE_DESKTOP=1

# Add Steam Controller udev rules
RUN curl -Lo /etc/udev/rules.d/99-steam-controller.rules \
  https://raw.githubusercontent.com/ValveSoftware/steam-devices/master/60-steam-input.rules

# Add current user to 'input' group (adjust if you're creating the user elsewhere)
# RUN usermod -aG input <your-username>  # handled post-install or via skel/user setup

# Expose required Steam Remote Play ports for Firewalld users (doc only)
# Suggest user runs:
#   firewall-cmd --zone=public --add-service=steam-streaming --permanent
#   firewall-cmd --zone=public --add-service=steam-streaming

# Optional: Create persistent Steam folder (if layering)
# RUN mkdir -p /var/home/steam && ln -s /var/home/steam /home/soltros/Steam

# Add terminal branding
RUN echo -e '\n\e[1;36mWelcome to SoltrOS — powered by Fedora Silverblue\e[0m\n' > /etc/issue

# Update icon cache
RUN gtk-update-icon-cache -f /usr/share/icons/hicolor

# Clean up
RUN dnf clean all

LABEL org.opencontainers.image.title="SoltrOS" \
      org.opencontainers.image.description="Gaming-tuned, minimal Fedora-based GNOME image with Waterfox and RPMFusion apps"

