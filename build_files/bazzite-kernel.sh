#!/bin/bash
# bazzite-kernel.sh - Auto-install latest Bazzite kernel
set -euo pipefail

echo "Starting Bazzite kernel installation..."

# GitHub repository information
GITHUB_REPO="bazzite-org/kernel-bazzite"
GITHUB_API_URL="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"

# Detect system architecture
ARCH=$(uname -m)
echo "Detected architecture: ${ARCH}"

# Create temporary directory
TEMP_DIR="/tmp/bazzite-kernel"
mkdir -p "${TEMP_DIR}"

# Get latest release information from GitHub API
echo "Fetching latest release information from GitHub..."
RELEASE_DATA=$(curl -s "${GITHUB_API_URL}")

if [ -z "${RELEASE_DATA}" ]; then
    echo "ERROR: Failed to fetch release data from GitHub API"
    exit 1
fi

# Extract version tag
VERSION_TAG=$(echo "${RELEASE_DATA}" | jq -r '.tag_name')
echo "Latest Bazzite kernel version: ${VERSION_TAG}"

# Extract RPM download URLs for current architecture
echo "Extracting RPM download URLs for ${ARCH}..."
RPM_URLS=$(echo "${RELEASE_DATA}" | jq -r --arg arch "${ARCH}" \
    '.assets[] | select(.name | endswith(".rpm") and contains($arch)) | .browser_download_url')

if [ -z "${RPM_URLS}" ]; then
    echo "ERROR: No RPM packages found for architecture ${ARCH}"
    exit 1
fi

# Count packages to download
PACKAGE_COUNT=$(echo "${RPM_URLS}" | wc -l)
echo "Found ${PACKAGE_COUNT} packages to download"

# Download all RPM packages
echo "Downloading Bazzite kernel packages..."
cd "${TEMP_DIR}"

DOWNLOADED_COUNT=0
while IFS= read -r url; do
    if [ -n "${url}" ]; then
        PACKAGE_NAME=$(basename "${url}")
        echo "Downloading: ${PACKAGE_NAME}"
        
        if curl -sL -o "${PACKAGE_NAME}" "${url}"; then
            ((DOWNLOADED_COUNT++))
            echo "✓ Downloaded: ${PACKAGE_NAME}"
        else
            echo "✗ Failed to download: ${PACKAGE_NAME}"
            rm -rf "${TEMP_DIR}"
            exit 1
        fi
    fi
done <<< "${RPM_URLS}"

echo "Successfully downloaded ${DOWNLOADED_COUNT} packages"

# List downloaded packages for verification
echo "Downloaded packages:"
ls -la "${TEMP_DIR}"/*.rpm

# Remove existing Fedora kernel packages (if any)
echo "Removing existing Fedora kernel packages..."
rpm -qa | grep -E '^kernel' | xargs -r rpm -e --nodeps 2>/dev/null || echo "No existing kernel packages to remove"

# Clean any leftover kernel files
echo "Cleaning up any remaining kernel files..."
rm -rf /lib/modules/[0-9]* 2>/dev/null || true
rm -rf /boot/vmlinuz-* /boot/initramfs-* /boot/System.map-* /boot/config-* 2>/dev/null || true

# Install Bazzite kernel packages
echo "Installing Bazzite kernel packages..."
rpm -ivh --force --nodeps "${TEMP_DIR}"/*.rpm

# Verify installation
echo "Verifying Bazzite kernel installation..."
INSTALLED_KERNELS=$(rpm -qa | grep -E "^kernel.*bazzite" || true)

if [ -z "${INSTALLED_KERNELS}" ]; then
    echo "ERROR: No Bazzite kernel packages found after installation"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

echo "Successfully installed Bazzite kernel packages:"
echo "${INSTALLED_KERNELS}"

# Update initramfs for all installed kernels
echo "Updating initramfs..."
KERNEL_VERSIONS=$(rpm -qa --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-core 2>/dev/null | grep bazzite || true)
for kernel_version in ${KERNEL_VERSIONS}; do
    if [ -n "${kernel_version}" ]; then
        echo "Updating initramfs for kernel ${kernel_version}..."
        dracut --force --kver "${kernel_version}" 2>/dev/null || echo "Warning: Failed to update initramfs for ${kernel_version}"
    fi
done

# Update bootloader configuration if grub exists
if command -v grub2-mkconfig >/dev/null 2>&1 && [ -d /boot/grub2 ]; then
    echo "Updating bootloader configuration..."
    grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || echo "Warning: Failed to update GRUB configuration"
fi

# Clean package cache
echo "Cleaning package manager cache..."
dnf clean all 2>/dev/null || rpm --rebuilddb

# Clean up temporary files
echo "Cleaning up temporary files..."
rm -rf "${TEMP_DIR}"

echo "✓ Bazzite kernel installation completed successfully!"
echo "Installed kernel version: ${VERSION_TAG}"
echo "Architecture: ${ARCH}"
echo "Total packages installed: ${DOWNLOADED_COUNT}"