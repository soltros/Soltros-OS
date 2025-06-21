#!/bin/bash
set -euo pipefail

echo "Installing Bazzite kernel for container image..."

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

# For container builds, we need to disable kernel-install scripts that don't work in containers
# This is the proper approach for derived container images according to Fedora documentation

# Remove existing kernels first
echo "Removing Fedora CoreOS kernel packages..."
rpm -qa | grep '^kernel' | xargs -r rpm -e --nodeps 2>/dev/null || true

# Install Bazzite kernel with scripts disabled (proper for container builds)
echo "Installing Bazzite kernel packages (container mode)..."
rpm -ivh --force --nodeps --noscripts *.rpm

# Manually handle what the scripts would do, but in a container-safe way
KERNEL_VERSION=$(rpm -qa --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-core | grep bazzite | head -1)
if [ -n "$KERNEL_VERSION" ]; then
    echo "Setting up kernel $KERNEL_VERSION for container image..."
    
    # Create necessary directories
    mkdir -p /boot /lib/modules
    
    # The initramfs and bootloader will be handled by bootc/ostree at deployment time
    # We just need the kernel files in place
    echo "Kernel files installed successfully"
    
    # Verify installation
    echo "Installed kernel packages:"
    rpm -qa | grep bazzite
fi

# Cleanup
rm -rf /tmp/bazzite-rpms /tmp/rpm_urls.txt

echo "Bazzite kernel installation completed for container image"
echo "Kernel version: $KERNEL_VERSION"