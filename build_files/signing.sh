#!/usr/bin/bash
# SoltrOS: Container Signing Setup Script
# Author: Derrik
# Description: Configures container policy for ghcr.io/soltros containers
set ${SET_X:+-x} -eou pipefail

# Variables
NAMESPACE="soltros"
POLICY="/etc/containers/policy.json"

log() {
  echo "=== $* ==="
}

log "Preparing directories"
mkdir -p /etc/containers
mkdir -p /etc/pki/containers

log "Setting up policy.json"
cat > "$POLICY" << 'EOF'
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports": {
        "docker": {
            "ghcr.io/soltros": [
                {
                    "type": "insecureAcceptAnything"
                }
            ]
        },
        "docker-daemon": {
            "": [
                {
                    "type": "insecureAcceptAnything"
                }
            ]
        }
    }
}
EOF

log "Setting correct permissions"
chmod 644 "$POLICY"

log "Verifying policy configuration"
if command -v jq &> /dev/null; then
    jq empty "$POLICY"
fi

log "Policy setup complete"