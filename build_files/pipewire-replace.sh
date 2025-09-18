#!/usr/bin/env bash
set ${SET_X:+-x} -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

# 1) Remove PipeWire/WirePlumber and install PulseAudio stack
if command -v dnf5 >/dev/null 2>&1; then
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

  log "Installing PulseAudio stack via dnf5…"
  dnf5 install -y \
    pulseaudio \
    pulseaudio-utils \
    alsa-plugins-pulseaudio \
    pulseaudio-module-bluetooth \
    pulseaudio-qt || true

  # Clean up any dangling deps
  dnf5 autoremove -y || true
else
  log "dnf5 not found; using rpm-ostree override/remove…"
  rpm-ostree override remove \
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

  rpm-ostree install \
    pulseaudio \
    pulseaudio-utils \
    alsa-plugins-pulseaudio \
    pulseaudio-module-bluetooth \
    pulseaudio-qt

  rpm-ostree cleanup -m || true
fi

# 2) Make ALSA default to Pulse
printf '%s\n' 'pcm.!default pulse' 'ctl.!default pulse' > /etc/asound.conf

# 3) Mask PipeWire user units (GLOBAL), enable PulseAudio user unit (GLOBAL)
install -d -m 755 /etc/systemd/user
for u in pipewire.service pipewire.socket pipewire-pulse.service pipewire-pulse.socket wireplumber.service; do
  ln -sf /dev/null "/etc/systemd/user/$u"
done

# Enable pulseaudio.service for all users by default
install -d -m 755 /etc/systemd/user/default.target.wants
ln -sf /usr/lib/systemd/user/pulseaudio.service /etc/systemd/user/default.target.wants/pulseaudio.service

# 4) Guardrail: fail if PipeWire packages are still present
if rpm -qa | grep -q '^pipewire'; then
  echo "ERROR: PipeWire packages detected after purge:"
  rpm -qa | grep '^pipewire'
  exit 1
fi

log "[OK] Switched to PulseAudio by default; PipeWire/WirePlumber removed and masked"
