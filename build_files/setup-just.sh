#!/bin/bash
# Setup script for SoltrOS just integration
set -euo pipefail

echo "Setting up SoltrOS just integration..."

# Create necessary directories
mkdir -p /usr/share/soltros/just

# Create main SoltrOS justfile that imports the existing ublue-os justfile
cat > /usr/share/soltros/just/justfile << 'EOF'
# SoltrOS Main Justfile - integrates with ublue-os justfile

# Import the base ublue-os justfile (includes all existing recipes)
import "/usr/share/ublue-os/justfile"

# Import SoltrOS-specific recipes
import "/usr/share/soltros/just/soltros.just"
EOF

# Create shell configuration to use SoltrOS justfile by default
mkdir -p /etc/profile.d /etc/fish/conf.d

# Set JUSTFILE environment variable to point to SoltrOS justfile
cat > /etc/profile.d/soltros-just.sh << 'EOF'
# SoltrOS just configuration
export JUSTFILE="/usr/share/soltros/just/justfile"
EOF

cat > /etc/fish/conf.d/soltros-just.fish << 'EOF'
# SoltrOS just configuration
set -gx JUSTFILE "/usr/share/soltros/just/justfile"
EOF

echo "SoltrOS just integration setup complete!"
echo "Users can now run 'just' to access both ublue-os and SoltrOS recipes."
