#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}


log "Enabling soltros audio resume service"
chmod 755 /usr/libexec/soltros/soltros-resume-monitor.sh || true
systemctl enable soltros-resume-fix.service

log "Enabling Tailscale"
systemctl enable tailscaled.service
