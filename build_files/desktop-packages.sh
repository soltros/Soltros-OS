#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing RPM packages"

log "Enable Copr repos"

COPR_REPOS=(
    pgdev/ghostty
)
for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr enable "$repo"
done

log "Enable repositories"
# Bazzite disabled this for some reason so lets re-enable it again
dnf5 config-manager setopt terra.enabled=1 terra-extras.enabled=1

log "Install layered applications"

# Layered Applications
LAYERED_PACKAGES=(
    fish
    gimp
    mbpfan
    thermald
    lm_sensors
    tailscale
    gamemode
    papirus-icon-theme
    mangohud
    goverlay
    udisks2
    udiskie
    waterfox
    telegram-desktop
    discord
    vlc
)

dnf5 install --setopt=install_weak_deps=False --nogpgcheck -y "${LAYERED_PACKAGES[@]}"

log "Disable Copr repos as we do not need it anymore"

for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr disable "$repo"
done

