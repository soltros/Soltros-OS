#!/bin/bash
set -euo pipefail

echo "Installing Bazzite kernel..."

# Get architecture
ARCH=$(uname -m)

# Get latest release and extract RPM URLs
curl -s https://api.github.com/repos/bazzite-org/kernel-bazzite/releases/latest | \
jq -r --arg arch "$ARCH" '.assets[] | select(.name | endswith(".rpm") and contains($arch)) | .browser_download_url' > /tmp/rpm_urls.txt

# Download all RPMs
mkdir -p /tmp/bazzite-rpms
cd /tmp/bazzite-rpms

while read -r url; do
    curl -sL -O "$url"
done < /tmp/rpm_urls.txt

# Install Bazzite kernel
rpm -ivh --force --nodeps *.rpm

# Remove Fedora CoreOS kernel after Bazzite is installed
echo "Removing Fedora CoreOS kernel packages..."
FEDORA_KERNELS=$(rpm -qa | grep '^kernel' | grep -v bazzite || true)
if [ -n "$FEDORA_KERNELS" ]; then
    echo "Found Fedora kernels to remove: $FEDORA_KERNELS"
    echo "$FEDORA_KERNELS" | xargs -r rpm -e --nodeps || true
    echo "Fedora kernel removal completed"
else
    echo "No Fedora kernel packages found to remove"
fi

# Ensure bootloader setup for ostree systems
echo "Setting up bootloader for new kernel..."
KERNEL_VERSION=$(rpm -qa --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-core | grep bazzite | head -1)
if [ -n "$KERNEL_VERSION" ]; then
    echo "Found Bazzite kernel version: $KERNEL_VERSION"
    # For ostree systems, ensure kernel is properly staged
    if [ -f /boot/loader/entries ]; then
        ostree admin deploy --karg-proc-cmdline --os=fedora || true
    fi
fi

# Cleanup
rm -rf /tmp/bazzite-rpms /tmp/rpm_urls.txt

echo "Bazzite kernel installed"