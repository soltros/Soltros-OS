#!/usr/bin/bash
# SoltrOS: Container Signing Setup Script
# Author: Derrik
# Description: Configures sigstore signing trust for ghcr.io/soltros containers

set ${SET_X:+-x} -eou pipefail

# Variables
NAMESPACE="soltros"
PUBKEY="/etc/pki/containers/${NAMESPACE}.pub"
POLICY="/etc/containers/policy.json"
REGISTRY="ghcr.io/${NAMESPACE}"

log() {
  echo "=== $* ==="
}

log "Preparing directories"
mkdir -p /etc/containers
mkdir -p /etc/pki/containers
mkdir -p /etc/containers/registries.d/

log "Setting up secure policy.json"
cat > "$POLICY" << EOF
{
    "default": [
        {
            "type": "reject"
        }
    ],
    "transports": {
        "docker": {
            "$REGISTRY": [
                {
                    "type": "sigstoreSigned",
                    "keyPath": "$PUBKEY",
                    "signedIdentity": {
                        "type": "matchRepository"
                    }
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

log "Installing cosign public key"
if [ -f /ctx/soltros.pub ]; then
    # Legacy path for backward compatibility
    cp /ctx/soltros.pub "$PUBKEY"
else
    # Preferred path - key should be copied via Dockerfile
    if [ ! -f "$PUBKEY" ]; then
        echo "ERROR: Public key not found at /ctx/soltros.pub or $PUBKEY" >&2
        exit 1
    fi
fi

log "Setting correct permissions"
chmod 644 "$PUBKEY"
chmod 644 "$POLICY"

log "Creating registry policy YAML"
cat > "/etc/containers/registries.d/${NAMESPACE}.yaml" << EOF
docker:
  ${REGISTRY}:
    use-sigstore-attachments: true
EOF

log "Verifying policy configuration"
# Basic syntax check
jq empty "$POLICY"

log "Signing policy setup complete for $REGISTRY"