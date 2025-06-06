#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up SoltrOS just recipes integration"

# Verify that the soltros.just file was copied during build
if [ ! -f "/usr/share/soltros/just/soltros.just" ]; then
    log "ERROR: /usr/share/soltros/just/soltros.just not found!"
    log "Make sure system_files/usr/share/soltros/just/soltros.just is copied correctly"
    exit 1
fi

# Import SoltrOS recipes into the main ublue-os justfile
if [ -f "/usr/share/ublue-os/justfile" ]; then
    # Check if our import line already exists to avoid duplicates
    if ! grep -q "soltros.just" /usr/share/ublue-os/justfile; then
        echo "" >> /usr/share/ublue-os/justfile
        echo "# Import SoltrOS recipes" >> /usr/share/ublue-os/justfile
        echo "import \"/usr/share/soltros/just/soltros.just\"" >> /usr/share/ublue-os/justfile
        log "Added SoltrOS recipes import to ublue-os justfile"
    else
        log "SoltrOS recipes import already exists in ublue-os justfile"
    fi
else
    log "Warning: /usr/share/ublue-os/justfile not found"
fi

log "Hide incompatible Bazzite just recipes"
for recipe in "bazzite-cli" "install-coolercontrol" "install-openrgb"; do
  # Find files containing the recipe and hide it
  if find /usr/share/ublue-os/just/ -name "*.just" -exec grep -l "^$recipe:" {} \; 2>/dev/null | head -1 >/dev/null; then
    find /usr/share/ublue-os/just/ -name "*.just" -exec sed -i "s/^$recipe:/_$recipe:/" {} \;
    log "Hidden incompatible recipe: $recipe"
  else
    log "Recipe $recipe not found (may already be hidden or removed)"
  fi
done

log "SoltrOS just integration complete"
