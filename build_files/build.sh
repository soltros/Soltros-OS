#!/bin/bash

set ${SET_X:+-x} -eou pipefail

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

log() {
  echo "== $* =="
}

log "Starting SoltrOS build process"

# Base image for reference (though not used in conditional logic anymore)
BASE_IMAGE="${BASE_IMAGE:-ghcr.io/ublue-os/aurora-dx}"
log "Building for base image: $BASE_IMAGE"

log "Install server packages"
echo_group /ctx/server-packages.sh

log "Enable container signing"
echo_group /ctx/signing.sh

log "Install desktop packages"
echo_group /ctx/desktop-packages.sh

log "Setup just files"
echo_group /ctx/just-files.sh

log "Setup desktop defaults"
echo_group /ctx/desktop-defaults.sh

log "Apply system overrides"
echo_group /ctx/overrides.sh

# Check if setup_just.sh exists before calling it (for safety)
if [ -f "/ctx/setup_just.sh" ]; then
    log "Setup just"
    echo_group /ctx/setup_just.sh
fi

log "Post build cleanup"
echo_group /ctx/cleanup.sh

log "SoltrOS build process completed successfully"
