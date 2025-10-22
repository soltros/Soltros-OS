#!/usr/bin/bash
# SoltrOS: Container Signing Setup Script
# Author: Derrik
# Description: Configures GPG signing trust for ghcr.io/soltros containers
set ${SET_X:+-x} -eou pipefail

# Variables
NAMESPACE="soltros"
PUBKEY="/etc/pki/containers/${NAMESPACE}.pub"
POLICY="/etc/containers/policy.json"

log() {
  echo "=== $* ==="
}

log "Preparing directories"
mkdir -p /etc/containers
mkdir -p /etc/pki/containers
mkdir -p /etc/containers/registries.d/

log "Setting up secure policy.json"
cat > "$POLICY" << 'EOF'
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports": {
        "docker": {
            "ghcr.io/soltros/soltros-os": [
                {
                    "type": "signedBy",
                    "keyType": "GPGKeys",
                    "keyPath": "/etc/pki/containers/soltros.pub"
                }
            ],
            "ghcr.io/soltros/soltros-os_lts": [
                {
                    "type": "signedBy",
                    "keyType": "GPGKeys",
                    "keyPath": "/etc/pki/containers/soltros.pub"
                }
            ],
            "ghcr.io/soltros/soltros-lts_cosmic": [
                {
                    "type": "signedBy",
                    "keyType": "GPGKeys",
                    "keyPath": "/etc/pki/containers/soltros.pub"
                }
            ],
            "ghcr.io/soltros/soltros-unstable_cosmic": [
                {
                    "type": "signedBy",
                    "keyType": "GPGKeys",
                    "keyPath": "/etc/pki/containers/soltros.pub"
                }
            ],
            "ghcr.io/soltros/soltros-os-lts_gnome": [
                {
                    "type": "signedBy",
                    "keyType": "GPGKeys",
                    "keyPath": "/etc/pki/containers/soltros.pub"
                }
            ],
            "ghcr.io/soltros/soltros-os-unstable_gnome": [
                {
                    "type": "signedBy",
                    "keyType": "GPGKeys",
                    "keyPath": "/etc/pki/containers/soltros.pub"
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

log "Installing GPG public key"
if [ -f /ctx/soltros.pub ]; then
    cp /ctx/soltros.pub "$PUBKEY"
else
    if [ ! -f "$PUBKEY" ]; then
        echo "ERROR: Public key not found at /ctx/soltros.pub or $PUBKEY" >&2
        exit 1
    fi
fi

log "Setting correct permissions"
chmod 644 "$PUBKEY"
chmod 644 "$POLICY"

log "Creating registry signature configuration"
cat > "/etc/containers/registries.d/soltros.yaml" << EOF
docker:
  ghcr.io/soltros/soltros-os:
    sigstore: https://ghcr.io/soltros/signatures/soltros-os
  ghcr.io/soltros/soltros-os_lts:
    sigstore: https://ghcr.io/soltros/signatures/soltros-os_lts
  ghcr.io/soltros/soltros-lts_cosmic:
    sigstore: https://ghcr.io/soltros/signatures/soltros-lts_cosmic
  ghcr.io/soltros/soltros-unstable_cosmic:
    sigstore: https://ghcr.io/soltros/signatures/soltros-unstable_cosmic
  ghcr.io/soltros/soltros-os-lts_gnome:
    sigstore: https://ghcr.io/soltros/signatures/soltros-os-lts_gnome
  ghcr.io/soltros/soltros-os-unstable_gnome:
    sigstore: https://ghcr.io/soltros/signatures/soltros-os-unstable_gnome
EOF

log "Verifying policy configuration"
if command -v jq &> /dev/null; then
    jq empty "$POLICY"
fi

log "Signing policy setup complete"