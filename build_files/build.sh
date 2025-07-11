#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

# Define log function first (before any usage)
log() {
  echo "== $* =="
}

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

function echo_group() {
    local WHAT
    WHAT="$(
        basename "$1" .sh |
            tr "-" " " |
            tr "_" " "
    )"
    echo "::group:: == ${WHAT^^} =="
    "$1"
    echo "::endgroup::"
}

log "Starting SoltrOS build process"

# Base image for reference
BASE_IMAGE="${BASE_IMAGE:ghcr.io/ublue-os/base-main}"

log "Building for base image: $BASE_IMAGE"

log "Enable container signing"
echo_group /ctx/signing.sh

log "Setup /nix and download Determinite Systems Nix installer"
echo_group /ctx/nix-package-manager.sh

log "Install Waterfox browser BIN"
echo_group /ctx/waterfox-installer.sh

log "Install KDE Plasma Desktop"
echo_group /ctx/kde-desktop.sh

log "Install desktop packages"
echo_group /ctx/desktop-packages.sh

log "Setup desktop defaults"
echo_group /ctx/desktop-defaults.sh

log "Enabling gaming enhancements"
echo_group /ctx/gaming.sh

log "Apply system overrides"
echo_group /ctx/overrides.sh

log "Build InitramFS"
echo_group /ctx/build-initramfs.sh

log "Post build cleanup"
echo_group /ctx/cleanup.sh

log "SoltrOS build process completed successfully"