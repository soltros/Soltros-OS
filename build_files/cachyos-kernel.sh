#!/bin/bash
set -euo pipefail

echo "Installing CachyOS kernel with BORE scheduler..."

# Add CachyOS kernel repository
echo "Adding CachyOS kernel repository..."
FEDORA_VERSION=$(rpm -E %fedora)
REPO_URL="https://copr.fedorainfracloud.org/coprs/bieszczaders/kernel-cachyos/repo/fedora-${FEDORA_VERSION}/bieszczaders-kernel-cachyos-fedora-${FEDORA_VERSION}.repo"

curl -L -o /etc/yum.repos.d/bieszczaders-kernel-cachyos.repo "${REPO_URL}"

echo "Repository added successfully"

# Verify repository was added
if [ -f /etc/yum.repos.d/bieszczaders-kernel-cachyos.repo ]; then
    echo "✓ CachyOS kernel repository configured"
else
    echo "✗ Failed to add CachyOS kernel repository"
    exit 1
fi

# Replace Fedora kernel with CachyOS kernel
echo "Replacing Fedora kernel with CachyOS kernel..."
rpm-ostree override remove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra --install kernel-cachyos

echo "✓ CachyOS kernel installation completed"
echo "System will boot with CachyOS BORE scheduler kernel"