#!/usr/bin/bash
set -euo pipefail

log() {
  echo "=== $* ==="
}

log "Installing Bazzite kernel from COPR repositories"

# Install Bazzite kernel from their COPR repo
dnf5 -y install \
    kernel-bazzite \
    kernel-bazzite-modules \
    kernel-bazzite-modules-extra \
    kernel-bazzite-devel

# Install gaming schedulers
dnf5 -y install scx-scheds

# Version lock the kernel to prevent unwanted updates
dnf5 versionlock add \
    kernel-bazzite \
    kernel-bazzite-devel \
    kernel-bazzite-modules \
    kernel-bazzite-modules-extra

log "Bazzite kernel installation complete"