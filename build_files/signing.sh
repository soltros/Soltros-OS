#!/usr/bin/bash
# SoltrOS: Container Signing Setup Script
# Author: Derrik
# Description: Configures sigstore signing trust for ghcr.io/soltros containers

set ${SET_X:+-x} -eou pipefail
trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

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
mkdir -p /usr/etc/containers/

# Workaround for images like uCore using /usr/etc
if [ -f /usr/etc/containers/policy.json ]; then
    cp /usr/etc/containers/policy.json "$POLICY"
fi

log "Setting up policy.json for sigstore"
cat <<<"$(jq ".transports.docker |=. + {
   \"${REGISTRY}\": [
    {
        \"type\": \"sigstoreSigned\",
        \"keyPaths\": [\"${PUBKEY}\"],
        \"signedIdentity\": {
            \"type\": \"matchRepository\"
        }
    }
]}" <"$POLICY")" >"/tmp/policy.json"

cp /tmp/policy.json "$POLICY"

log "Copying cosign public key"
cp /ctx/cosign.pub "$PUBKEY"

log "Creating registry policy YAML"
tee "/etc/containers/registries.d/${NAMESPACE}.yaml" <<EOF
docker:
  ${REGISTRY}:
    use-sigstore-attachments: true
EOF

log "Sync policy to /usr/etc for compatibility"
cp "$POLICY" /usr/etc/containers/policy.json

log "Signing policy setup complete for $REGISTRY"

