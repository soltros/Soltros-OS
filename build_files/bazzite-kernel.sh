#!/bin/bash
set -euo pipefail

log() {
  echo "=== $* ==="
}

log "Installing Bazzite gaming-optimized kernel"

# Install kernel RPMs from mounted Bazzite akmods
dnf5 -y install /tmp/kernel-rpms/*.rpm /tmp/akmods-rpms/*.rpm

# Install gaming schedulers (from Bazzite)
dnf5 -y install scx-scheds

log "Bazzite kernel installation complete"