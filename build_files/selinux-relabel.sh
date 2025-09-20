#!/usr/bin/bash
set -euo pipefail

# Only schedule once
mkdir -p /etc/soltros
if [ -f /etc/soltros/.selinux_relabel_done ]; then
  exit 0
fi

# If this image is Alma-based, schedule an autorelabel the first time it boots.
# (This catches Fedora -> Alma rebases where policy stores differ.)
if [ -f /etc/almalinux-release ] || grep -qi '^ID=alma' /etc/os-release 2>/dev/null; then
  if [ ! -e /.autorelabel ]; then
    touch /.autorelabel
  fi
fi

touch /etc/soltros/.selinux_relabel_done
exit 0
