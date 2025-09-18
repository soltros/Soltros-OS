#!/usr/bin/env bash
set ${SET_X:+-x} -euo pipefail
trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG
log(){ echo "=== $* ==="; }

command -v dnf5 >/dev/null 2>&1 || { echo "dnf5 not found"; exit 1; }

# Common DNF opts: block pipewire/kpipewire everywhere, disable weak deps
DNF="dnf5 -y --setopt=install_weak_deps=False --exclude=pipewire* --exclude=kpipewire"

log "Configuring DNF excludes (defense-in-depth)…"
install -d -m 755 /etc/dnf/dnf.conf.d
cat >/etc/dnf/dnf.conf.d/10-audio-exclude.conf <<'EOF'
excludepkgs=pipewire*,kpipewire
install_weak_deps=False
EOF

# 1) Purge PipeWire stack (ignore already-removed pkgs)
log "Removing PipeWire stack…"
$DNF remove \
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

# 2) Install Pulse core
log "Installing PulseAudio stack…"
$DNF install \
  pulseaudio \
  pulseaudio-utils \
  alsa-plugins-pulseaudio \
  pulseaudio-module-bluetooth \
  pulseaudio-qt || true

# 3) Reinstall apps with Pulse-friendly backends
log "Reinstalling apps without PipeWire deps…"
$DNF install \
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

log "Autoremoving dangling deps…"
$DNF autoremove || true

# 4) ALSA -> Pulse default
printf '%s\n' 'pcm.!default pulse' 'ctl.!default pulse' > /etc/asound.conf

# 5) Mask PipeWire user units globally; enable Pulse user unit globally
install -d -m 755 /etc/systemd/user
for u in pipewire.service pipewire.socket pipewire-pulse.service pipewire-pulse.socket wireplumber.service; do
  ln -sf /dev/null "/etc/systemd/user/$u"
done
install -d -m 755 /etc/systemd/user/default.target.wants
ln -sf /usr/lib/systemd/user/pulseaudio.service /etc/systemd/user/default.target.wants/pulseaudio.service

# 6) Guardrail: if any pipewire* snuck back, show the culprits and fail
if rpm -qa | grep -q '^pipewire'; then
  echo "ERROR: PipeWire packages detected after purge/reinstall:"
  rpm -qa | grep '^pipewire' | sort
  echo
  echo "Reverse deps (who is pulling it in):"
  for p in pipewire pipewire-alsa pipewire-pulseaudio kpipewire; do
    dnf5 repoquery --whatrequires "$p" || true
  done
  exit 1
fi

log "[OK] PulseAudio active, PipeWire purged and masked."
