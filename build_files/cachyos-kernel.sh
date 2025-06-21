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

# First, check what kernel packages are actually installed
echo "Checking installed kernel packages..."
INSTALLED_KERNELS=$(rpm -qa | grep '^kernel' || true)
echo "Found kernel packages: $INSTALLED_KERNELS"

# Build the removal command based on what's actually installed
REMOVE_PACKAGES=""
for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do
    if rpm -q "$pkg" >/dev/null 2>&1; then
        REMOVE_PACKAGES="$REMOVE_PACKAGES $pkg"
        echo "Will remove: $pkg"
    else
        echo "Package not installed: $pkg"
    fi
done

# Remove existing kernel packages and install CachyOS kernel
if [ -n "$REMOVE_PACKAGES" ]; then
    echo "Removing packages:$REMOVE_PACKAGES"
    rpm-ostree override remove $REMOVE_PACKAGES --install kernel-cachyos
else
    echo "No kernel packages to remove, just installing CachyOS kernel"
    rpm-ostree install kernel-cachyos
fi

echo "✓ CachyOS kernel installation completed"
echo "System will boot with CachyOS BORE scheduler kernel"