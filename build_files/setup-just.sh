#!/bin/bash
# Setup script for SoltrOS just integration
set ${SET_X:+-x} -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Setting up SoltrOS just integration"

# Create necessary directories
mkdir -p /usr/share/soltros/just

# The soltros.just file should already be copied from system_files/
# Let's verify it exists
if [ ! -f "/usr/share/soltros/just/soltros.just" ]; then
    log "ERROR: soltros.just file not found! Make sure system_files/usr/share/soltros/just/soltros.just is properly copied."
    exit 1
fi

# Create main SoltrOS justfile that imports both ublue-os and soltros justfiles
cat > /usr/share/soltros/just/justfile << 'EOF'
# SoltrOS Main Justfile - integrates with ublue-os justfile

# Import the base ublue-os justfile (includes all existing recipes)
import "/usr/share/ublue-os/justfile"

# Import SoltrOS-specific recipes
import "/usr/share/soltros/just/soltros.just"
EOF

# Set JUSTFILE environment variable to point to SoltrOS justfile
mkdir -p /etc/profile.d /etc/fish/conf.d

cat > /etc/profile.d/soltros-just.sh << 'EOF'
# SoltrOS just configuration - set default justfile location
export JUSTFILE="/usr/share/soltros/just/justfile"
EOF

cat > /etc/fish/conf.d/soltros-just.fish << 'EOF'
# SoltrOS just configuration - set default justfile location
set -gx JUSTFILE "/usr/share/soltros/just/justfile"
EOF

# Also update the existing ublue-os justfile to include our recipes (fallback)
if [ -f "/usr/share/ublue-os/justfile" ]; then
    # Check if our import line already exists
    if ! grep -q "soltros.just" /usr/share/ublue-os/justfile; then
        echo "" >> /usr/share/ublue-os/justfile
        echo "# Import SoltrOS recipes" >> /usr/share/ublue-os/justfile
        echo "import \"/usr/share/soltros/just/soltros.just\"" >> /usr/share/ublue-os/justfile
        log "Added SoltrOS import to ublue-os justfile as fallback"
    fi
fi

log "SoltrOS just integration setup complete!"
log "Users can now run 'just' to access both ublue-os and SoltrOS recipes."
