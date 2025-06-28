#!/usr/bin/bash
# build_files/cachyos-kernel.sh
set -euo pipefail

log() {
  echo "=== $* ==="
}

log "Installing CachyOS kernel"

# Double-check default kernel removal (should already be done in Dockerfile)
log "Ensuring default kernel packages are removed"
dnf5 -y remove --no-autoremove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra || true

# Install CachyOS kernel
log "Installing CachyOS kernel from COPR"
if ! dnf5 -y install kernel-cachyos; then
    log "Failed to install kernel-cachyos, trying alternative installation methods"
    
    # List available cachyos packages for debugging
    log "Available CachyOS packages:"
    dnf5 search kernel-cachyos || true
    dnf5 search cachyos || true
    
    # Try different possible package names
    if dnf5 -y install kernel-cachyos-core kernel-cachyos-modules; then
        log "Installed CachyOS kernel components separately"
    elif dnf5 -y install cachyos-kernel; then
        log "Installed alternative CachyOS kernel package"
    else
        log "ERROR: All CachyOS kernel installation attempts failed"
        exit 1
    fi
fi

# Verify kernel installation
log "Verifying kernel installation"
if ls /usr/lib/modules/*/vmlinuz 2>/dev/null; then
    log "Kernel found in modules directory"
    ls -la /usr/lib/modules/*/vmlinuz
elif ls /boot/vmlinuz-* 2>/dev/null; then
    log "Kernel found in boot directory"
    ls -la /boot/vmlinuz-*
else
    log "WARNING: No kernel binary found after installation"
    log "Available modules:"
    ls -la /usr/lib/modules/ || true
    log "Boot contents:"
    ls -la /boot/ || true
fi

# List installed kernel packages for verification
log "Installed kernel packages:"
dnf5 list installed | grep -i kernel || true

log "CachyOS kernel installation complete"