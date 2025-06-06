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

# Remove specific /usr/etc subdirectories that aren't needed
# But preserve /usr/etc/containers which signing.sh creates
if [ -d "/usr/etc" ]; then
    # Remove unnecessary subdirectories but keep containers
    find /usr/etc -mindepth 1 -maxdepth 1 -type d ! -name "containers" -exec rm -rf {} + 2>/dev/null || true
    # Remove files in /usr/etc root but not subdirectories
    find /usr/etc -maxdepth 1 -type f -delete 2>/dev/null || true
fi

# Remove build artifacts
rm -f /.nvimlog

# Clean any leftover rpm-ostree config files at root level
rm -f /40-rpmostree-pkg-usermod*.conf 2>/dev/null || true

# Restore and setup required directories with correct permissions
mkdir -p /tmp && chmod 1777 /tmp
mkdir -p /var/tmp && chmod 1777 /var/tmp
mkdir -p /var/cache
mkdir -p /var/log

log "Cleanup completed"

# Validate container and commit changes
bootc container lint
ostree container commit
