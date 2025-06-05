#!/bin/bash
# Setup script for SoltrOS just wrapper

set -euo pipefail

echo "Setting up SoltrOS just wrapper..."

# Create necessary directories
mkdir -p /etc/profile.d /etc/fish/conf.d /usr/local/bin

# Create the soltros-just wrapper script
cat > /usr/local/bin/soltros-just << 'EOF'
#!/bin/bash
exec just --justfile /usr/share/soltros/just/justfile "$@"
EOF

# Make it executable
chmod +x /usr/local/bin/soltros-just

# Create shell aliases
echo 'alias just="soltros-just"' > /etc/profile.d/soltros-just.sh
echo 'alias just="soltros-just"' > /etc/fish/conf.d/soltros-just.fish

echo "SoltrOS just wrapper setup complete!"
echo "Users can now run 'just' to access SoltrOS recipes from anywhere."
