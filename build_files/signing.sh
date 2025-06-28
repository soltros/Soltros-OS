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

log "Setting up policy.json for sigstore"
# Handle existing policy from base image
if [ -f /usr/etc/containers/policy.json ]; then
    cp /usr/etc/containers/policy.json "$POLICY"
elif [ ! -f "$POLICY" ]; then
    # Create basic policy if none exists
    cat > "$POLICY" << 'EOF'
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports": {
        "docker-daemon": {
            "": [
                {
                    "type": "insecureAcceptAnything"
                }
            ]
        },
        "docker": {}
    }
}
EOF
fi

# Add sigstore configuration for our registry
jq ".transports.docker[\"${REGISTRY}\"] = [{
    \"type\": \"sigstoreSigned\",
    \"keyPaths\": [\"${PUBKEY}\"],
    \"signedIdentity\": {
        \"type\": \"matchRepository\"
    }
}]" "$POLICY" > /tmp/policy.json && mv /tmp/policy.json "$POLICY"

log "Copying cosign public key"
cp /ctx/soltros.pub "$PUBKEY"

log "Creating registry policy YAML"
cat > "/etc/containers/registries.d/${NAMESPACE}.yaml" << EOF
docker:
  ${REGISTRY}:
    use-sigstore-attachments: true
EOF

log "Signing policy setup complete for $REGISTRY"