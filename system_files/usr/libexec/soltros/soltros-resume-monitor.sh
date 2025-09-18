#!/usr/bin/env bash
set -euo pipefail

log() { logger -t soltros-resume "$*"; }

fix_audio_after_resume() {
  log "Resume detected: triggering udev for sound…"
  udevadm trigger --subsystem-match=sound --action=change || true
  udevadm trigger --subsystem-match=input --property-match=ID_AUDIO=1 --action=change || true
  udevadm settle || true

  for dev in /sys/class/sound/card*/device 2>/dev/null; do
    [[ -w "$dev/rescan" ]] && echo 1 > "$dev/rescan" || true
  done

  # If you later decide to ship alsa-utils, uncomment:
  # command -v alsactl >/dev/null 2>&1 && alsactl restore || true

  log "Resume fix completed."
}

# Use busctl (comes with systemd) to watch logind's PrepareForSleep signals.
# Output includes e.g.: "PrepareForSleep(boolean false)"
busctl monitor org.freedesktop.login1 |
  awk '/PrepareForSleep\(boolean/{ if ($0 ~ /false/) print "resume"; else print "sleep" }' |
  while read -r ev; do
    [[ "$ev" == "resume" ]] && fix_audio_after_resume
  done
