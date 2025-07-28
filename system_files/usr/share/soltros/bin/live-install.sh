#!/usr/bin/env bash
set -euo pipefail

IMAGE="ghcr.io/soltros/soltros-os:latest"

echo "=== SoltrOS Installer ==="

# Prompt for target device
read -rp "Enter target disk (e.g., /dev/sda or /dev/nvme0n1): " TARGET

# Basic sanity checks
if [ ! -b "$TARGET" ]; then
    echo "❌ Error: $TARGET is not a valid block device."
    exit 1
fi

echo "⚠️  WARNING: This will erase all data on $TARGET"
read -rp "Are you sure you want to continue? (yes/[no]): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

echo "🔄 Pulling image: $IMAGE"
# Optionally pre-pull the image (not required; bootc does it)
podman pull "$IMAGE" || true

echo "🚀 Installing SoltrOS to $TARGET"
sudo bootc install --image "$IMAGE" --target "$TARGET"

echo "✅ Install complete!"
echo "You can now reboot into your new SoltrOS installation."
