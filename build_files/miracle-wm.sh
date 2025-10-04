#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Configuring SoltrOS Miracle WM Edition"

# Configure SDDM to exclude Nix build users
configure_sddm() {
    log "Configuring SDDM to hide Nix build users"
    
    mkdir -p /etc/sddm.conf.d
    
    cat > /etc/sddm.conf.d/10-hide-users.conf <<EOF
[Users]
# Hide system users and Nix build users from login screen
HideUsers=nixbld1,nixbld2,nixbld3,nixbld4,nixbld5,nixbld6,nixbld7,nixbld8,nixbld9,nixbld10,nixbld11,nixbld12,nixbld13,nixbld14,nixbld15,nixbld16,nixbld17,nixbld18,nixbld19,nixbld20,nixbld21,nixbld22,nixbld23,nixbld24,nixbld25,nixbld26,nixbld27,nixbld28,nixbld29,nixbld30,nixbld31,nixbld32
HideShells=/sbin/nologin,/bin/false
MinimumUid=1000
EOF
    
    log "SDDM configuration complete"
}

configure_sddm

log "SoltrOS Miracle WM configuration complete"