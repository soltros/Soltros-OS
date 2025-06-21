#!/usr/bin/bash
set ${SET_X:+-x} -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Starting system cleanup"

# Clean package manager cache
dnf5 clean all

# Clean temporary files but preserve important directories
rm -rf /tmp/*
rm -rf /var/tmp/*
rm -rf /var/cache/*
rm -rf /var/log/*

# Clean DNF cache and repos that cause lint failures
rm -rf /var/lib/dnf/repos/*

# Remove /usr/etc entirely as bootc doesn't support it
# The signing script already copies to /etc/containers/policy.json
rm -rf /usr/etc

# Remove build artifacts
rm -f /.nvimlog

# Clean any leftover rpm-ostree config files at root level
rm -f /40-rpmostree-pkg-usermod*.conf 2>/dev/null || true

# Fix /var/run - it must be a symlink to /run for bootc containers
if [ -d /var/run ] && [ ! -L /var/run ]; then
    log "Fixing /var/run symlink"
    rm -rf /var/run
    ln -sf /run /var/run
fi

# Restore and setup required directories with correct permissions
mkdir -p /tmp && chmod 1777 /tmp
mkdir -p /var/tmp && chmod 1777 /var/tmp
mkdir -p /var/cache
mkdir -p /var/log

log "Cleanup completed"

# Validate container and commit changes
#bootc container lint
#ostree container commit
