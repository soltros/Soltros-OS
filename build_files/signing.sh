#!/usr/bin/bash
# SoltrOS: Container Signing Setup Script
# Author: Derrik
# Description: Configures sigstore signing trust for ghcr.io/soltros containers
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
                    "type": "sigstoreSigned",
                    "keyPath": "/etc/pki/containers/soltros.pub",
                    "signedIdentity": {
                        "type": "matchRepository"
                    }
                }
            ],
            "ghcr.io/soltros/soltros-os_lts": [
                {
                    "type": "sigstoreSigned",
                    "keyPath": "/etc/pki/containers/soltros.pub",
                    "signedIdentity": {
                        "type": "matchRepository"
                    }
                }
            ],
            "ghcr.io/soltros/soltros-lts_cosmic": [
                {
                    "type": "sigstoreSigned",
                    "keyPath": "/etc/pki/containers/soltros.pub",
                    "signedIdentity": {
                        "type": "matchRepository"
                    }
                }
            ],
            "ghcr.io/soltros/soltros-unstable_cosmic": [
                {
                    "type": "sigstoreSigned",
                    "keyPath": "/etc/pki/containers/soltros.pub",
                    "signedIdentity": {
                        "type": "matchRepository"
                    }
                }
            ],
            "ghcr.io/soltros/soltros-os-lts_gnome": [
                {
                    "type": "sigstoreSigned",
                    "keyPath": "/etc/pki/containers/soltros.pub",
                    "signedIdentity": {
                        "type": "matchRepository"
                    }
                }
            ],
            "ghcr.io/soltros/soltros-os-unstable_gnome": [
                {
                    "type": "sigstoreSigned",
                    "keyPath": "/etc/pki/containers/soltros.pub",
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

log "Creating registry policy YAML"
cat > "/etc/containers/registries.d/soltros.yaml" << 'EOF'
docker:
  ghcr.io/soltros/soltros-os:
    use-sigstore-attachments: true
  ghcr.io/soltros/soltros-os_lts:
    use-sigstore-attachments: true
  ghcr.io/soltros/soltros-lts_cosmic:
    use-sigstore-attachments: true
  ghcr.io/soltros/soltros-unstable_cosmic:
    use-sigstore-attachments: true
  ghcr.io/soltros/soltros-os-lts_gnome:
    use-sigstore-attachments: true
  ghcr.io/soltros/soltros-os-unstable_gnome:
    use-sigstore-attachments: true
EOF

log "Verifying policy configuration"
if command -v jq &> /dev/null; then
    jq empty "$POLICY"
fi

log "Signing policy setup complete"