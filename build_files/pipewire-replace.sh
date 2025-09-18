#!/usr/bin/env bash
set ${SET_X:+-x} -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

# 0) Harden DNF: prevent PipeWire from being pulled back in
log "Configuring DNF excludes for PipeWire…"
install -d -m 755 /etc/dnf/dnf.conf.d
cat >/etc/dnf/dnf.conf.d/10-audio-exclude.conf <<'EOF'
excludepkgs=pipewire*,kpipewire
install_weak_deps=False
EOF

# 1) Remove PipeWire stack
log "Removing PipeWire stack via dnf5…"
dnf5 remove -y \
  pipewire \
  pipewire-alsa \
  pipewire-pulseaudio \
  pipewire-jack-audio-connection-kit \
  pipewire-jack-audio-connection-kit-libs \
  pipewire-gstreamer \
  pipewire-utils \
  pipewire-libs \
  pipewire-config-raop \
  pipewire-plugin-libcamera \
  kpipewire \
  vlc-plugin-pipewire \
  qemu-audio-pipewire || true

# 2) Install PulseAudio stack
log "Installing PulseAudio stack via dnf5…"
dnf5 install -y \
  pulseaudio \
  pulseaudio-utils \
  alsa-plugins-pulseaudio \
  pulseaudio-module-bluetooth \
  pulseaudio-qt || true

# 3) Reinstall apps with Pulse-friendly backends (no PipeWire deps)
log "Reinstalling affected apps with Pulse equivalents…"
dnf5 install -y \
  gnome-boxes \
  libvirt-daemon-kvm \
  libvirt-daemon-driver-qemu \
  libvirt-daemon-driver-storage-core \
  qemu-audio-pa \
  vlc \
  vlc-plugin-pulseaudio \
  k3b \
  ktorrent \
  khelpcenter \
  kdeplasma-addons \
  plasma-print-manager \
  plasma-nm-openconnect \
  neochat \
  digikam \
  digikam-libs \
  hugin-base \
  enblend \
  opencv-imgcodecs \
  gdal-libs \
  netcdf \
  libarrow \
  libarrow-acero-libs \
  libarrow-dataset-libs \
  parquet-libs \
  libspatialite \
  glusterfs \
  glusterfs-cli \
  glusterfs-fuse \
  webkit2gtk4.1 || true

# 4) Clean up dangling deps
log "Autoremoving unused packages…"
dnf5 autoremove -y || true

# 5) Make ALSA default to Pulse
printf '%s\n' 'pcm.!default pulse' 'ctl.!default pulse' > /etc/asound.conf

# 6) Mask PipeWire user units (GLOBAL), enable PulseAudio user unit (GLOBAL)
install -d -m 755 /etc/systemd/user
for u in pipewire.service pipewire.socket pipewire-pulse.service pipewire-pulse.socket wireplumber.service; do
  ln -sf /dev/null "/etc/systemd/user/$u"
done

install -d -m 755 /etc/systemd/user/default.target.wants
ln -sf /usr/lib/systemd/user/pulseaudio.service /etc/systemd/user/default.target.wants/pulseaudio.service

# 7) Guardrail: fail if PipeWire packages are still present
if rpm -qa | grep -q '^pipewire'; then
  echo "ERROR: PipeWire packages detected after purge/reinstall:"
  rpm -qa | grep '^pipewire'
  exit 1
fi

log "[OK] Switched to PulseAudio by default; reinstalled apps with Pulse; PipeWire masked"
