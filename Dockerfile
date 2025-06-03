# SoltrOS base
FROM ghcr.io/ublue-os/silverblue-main
LABEL org.opencontainers.image.title="SoltrOS"
LABEL org.opencontainers.image.description="Vanilla GNOME, gaming-ready Fedora image with MacBook support"
LABEL org.opencontainers.image.vendor="Derrik"
LABEL org.opencontainers.image.version="42"

# Add in Flathub
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Add RPM Fusion free/nonfree and repositories first
RUN rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Add the Terra repository
ADD https://terra.fyralabs.com/terra.repo /etc/yum.repos.d/terra.repo

# Add the Tailscale repository
COPY tailscale.repo /etc/yum.repos.d/tailscale.repo

### Flatpak stuff
# Ensure dbus run directory exists and setup machine ID
RUN systemd-machine-id-setup && \
    dbus-uuidgen > /etc/machine-id && \
    install -d /run/dbus

# Install Flatpaks with proper Steam permissions
RUN dbus-daemon --system --fork && \
    flatpak install -y --system --noninteractive flathub \
        com.valvesoftware.Steam \
        com.github.tchx84.Flatseal \
        com.bitwarden.desktop \
        org.filezillaproject.Filezilla \
        im.riot.Riot \
        com.github.iwalton3.jellyfin-media-player \
        io.github.shiftey.Desktop \
        io.github.dweymouth.supersonic \
        com.github.wwmm.easyeffects \
        com.mattjakeman.ExtensionManager \
        com.github.Matoking.protontricks \
        io.github.fastrizwaan.WineZGUI \
        com.ranfdev.DistroShelf \
        it.mijorus.gearlever \
        io.github.flattool.Warehouse \
        io.github.flattool.Ignition \
        io.missioncenter.MissionCenter \
        com.vysp3r.ProtonPlus \
        org.gnome.Calculator \
        org.gnome.Calendar \
        org.gnome.Characters \
        org.gnome.Contacts \
        org.gnome.Papers \
        org.gnome.Logs \
        org.gnome.Loupe \
        org.gnome.NautilusPreviewer \
        org.gnome.TextEditor \
        org.gnome.Weather \
        org.gnome.baobab \
        org.gnome.clocks \
        org.gnome.font-viewer \
        io.github.nokse22.Exhibit \
        de.leopoldluley.Clapgrep \
        org.freedesktop.Platform.VulkanLayer.MangoHud//23.08 \
        org.freedesktop.Platform.VulkanLayer.vkBasalt//23.08 \
        org.freedesktop.Platform.VulkanLayer.OBSVkCapture//23.08 \
        com.obsproject.Studio.Plugin.OBSVkCapture \
        com.obsproject.Studio.Plugin.Gstreamer \
        com.obsproject.Studio.Plugin.GStreamerVaapi \
        org.gtk.Gtk3theme.adw-gtk3//3.22 \
        org.gtk.Gtk3theme.adw-gtk3-dark//3.22 && \
    flatpak override --system com.valvesoftware.Steam \
        --filesystem=/run/media \
        --filesystem=/media \
        --filesystem=/mnt \
        --filesystem=home \
        --device=dri && \
    pkill dbus-daemon

# Remove Firefox first
RUN rpm-ostree override remove firefox firefox-langpacks

# Install default apps and automount support
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
    goverlay \
    udisks2 \
    udiskie

# Install Waterfox
ADD https://download.opensuse.org/repositories/home:/hawkeye116477:/waterfox/Fedora_41/x86_64/waterfox-6.5.6-1.21.x86_64.rpm /tmp/waterfox.rpm
RUN rpm-ostree install /tmp/waterfox.rpm && rm /tmp/waterfox.rpm

# Enable services
RUN systemctl enable tailscaled.service udisks2.service

# Add SoltrOS icons
COPY soltros-logo.png /usr/share/icons/hicolor/128x128/apps/fedora-logo.png
COPY soltros-logo.png /usr/share/icons/hicolor/256x256/apps/fedora-logo.png
COPY soltros-logo.png /usr/share/icons/hicolor/512x512/apps/fedora-logo.png
COPY soltros-logo.png /usr/share/pixmaps/fedora-gdm-logo.png
COPY soltros-logo.png /usr/share/pixmaps/fedora_whitelogo_med.png
COPY fedora-gdm-logo.png /usr/share/pixmaps/fedora-gdm-logo.png
COPY fedora_whitelogo_med.png /usr/share/pixmaps/fedora_whitelogo_med.png

# Add SoltrOS identity files
RUN curl -L https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/os-release -o /usr/lib/os-release
