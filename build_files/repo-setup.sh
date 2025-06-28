#!/usr/bin/bash
set -euo pipefail

log() {
  echo "=== $* ==="
}

log "Setting up repositories including Bazzite COPR repos"

# Install DNF5 plugins first
dnf5 -y install dnf5-plugins

# Enable Bazzite COPR repositories
for copr in \
    bazzite-org/bazzite \
    bazzite-org/bazzite-multilib \
    bazzite-org/LatencyFleX \
    bazzite-org/obs-vkcapture \
    ublue-os/staging \
    ublue-os/packages; \
do \
    echo "Enabling copr: $copr"; \
    dnf5 -y copr enable $copr; \
    dnf5 -y config-manager setopt copr:copr.fedorainfracloud.org:${copr////:}.priority=98; \
done

# Enable RPM Fusion
dnf5 -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Add Terra repo
curl --retry 3 -Lo /etc/yum.repos.d/terra.repo https://terra.fyralabs.com/terra.repo

# Set repository priorities (Bazzite repos get highest priority)
dnf5 -y config-manager setopt "*bazzite*".priority=1
dnf5 -y config-manager setopt "*akmods*".priority=2
dnf5 -y config-manager setopt "*terra*".priority=3
dnf5 -y config-manager setopt "*rpmfusion*".priority=5

log "Repository setup complete"