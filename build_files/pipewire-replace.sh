#!/usr/bin/env bash
set -euo pipefail

# 1) Remove PipeWire/WirePlumber (ignore if missing)
rpm-ostree override remove \
  pipewire pipewire-alsa pipewire-pulseaudio pipewire-jack wireplumber || true

# 2) Install PulseAudio stack
rpm-ostree install pulseaudio pulseaudio-utils alsa-plugins-pulseaudio pulseaudio-module-bluetooth
rpm-ostree cleanup -m

# 3) Make ALSA default to Pulse
printf '%s\n' 'pcm.!default pulse' 'ctl.!default pulse' > /etc/asound.conf

# 4) Mask PipeWire user units (GLOBAL), enable PulseAudio user unit (GLOBAL)
# (Do this via filesystem, not `systemctl`, to be build-safe)
install -d -m 755 /etc/systemd/user
for u in pipewire.service pipewire.socket pipewire-pulse.service pipewire-pulse.socket wireplumber.service; do
  ln -sf /dev/null "/etc/systemd/user/$u"
done

# Enable pulseaudio.service for all users by default
install -d -m 755 /etc/systemd/user/default.target.wants
ln -sf /usr/lib/systemd/user/pulseaudio.service /etc/systemd/user/default.target.wants/pulseaudio.service

# 5) (Optional) If you kept the resume monitor files around, you can skip enabling them now,
# since Pulse doesn't need the PipeWire restart. If you still want the udev nudge:
# ln -sv /usr/lib/systemd/system/soltros-resume-fix.service \
#        /etc/systemd/system/multi-user.target.wants/soltros-resume-fix.service || true

echo "[OK] Switched to PulseAudio by default; PipeWire/WirePlumber masked"
