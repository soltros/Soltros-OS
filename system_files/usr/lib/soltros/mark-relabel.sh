#!/usr/bin/env bash
set -euo pipefail

MARKER="/etc/soltros/relabel-required"
DONE="/var/lib/soltros/relabel-done"

mkdir -p /var/lib/soltros

if [[ -f "$DONE" ]]; then
  exit 0
fi

if command -v selinuxenabled >/dev/null 2>&1 && selinuxenabled; then
  echo "[soltros-relabel] Marking system for SELinux autorelabel on next boot..."
  touch /.autorelabel
else
  echo "[soltros-relabel] SELinux not enabled; skipping."
fi

rm -f "$MARKER"
touch "$DONE"

echo "[soltros-relabel] Requesting reboot to begin relabel..."
systemctl --no-block reboot || true
