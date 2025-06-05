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

log "Install server packages"
echo_group /ctx/server-packages.sh

log "Enable container signing"
BASE_IMAGE="${BASE_IMAGE:-ghcr.io/ublue-os/bluefin}"
echo_group /ctx/signing.sh

case "$BASE_IMAGE" in
*"/bazzite"*)
    echo_group /ctx/desktop-packages.sh
    echo_group /ctx/just-files.sh
    echo_group /ctx/desktop-defaults.sh
    ;;
*"/ucore"*) ;;
esac

echo_group /ctx/overrides.sh

log "Setup just"
echo_group /ctx/setup_just.sh

log "Post build cleanup"
echo_group /ctx/cleanup.sh
