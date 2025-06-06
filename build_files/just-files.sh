#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up SoltrOS just recipes integration"

# Import SoltrOS recipes into the main ublue-os justfile
echo "import \"/usr/share/soltros/just/soltros.just\"" >> /usr/share/ublue-os/justfile

log "Hide incompatible Bazzite just recipes"
for recipe in "bazzite-cli" "install-coolercontrol" "install-openrgb"; do
  # Find files containing the recipe and hide it
  if grep -l "^$recipe:" /usr/share/ublue-os/just/*.just >/dev/null 2>&1; then
    sed -i "s/^$recipe:/_$recipe:/" /usr/share/ublue-os/just/*.just
    echo "Hidden incompatible recipe: $recipe"
  else
    echo "Warning: Recipe $recipe not found (may already be hidden or removed)"
  fi
done

log "SoltrOS just integration complete"
