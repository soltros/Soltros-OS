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

# Install Bazzite kernel (disable problematic scripts for container builds)
rpm -ivh --force --nodeps --noscripts *.rpm

# Remove Fedora CoreOS kernel after Bazzite is installed
rpm -qa | grep '^kernel' | grep -v bazzite | xargs -r rpm -e --nodeps 2>/dev/null || true

# Cleanup
rm -rf /tmp/bazzite-rpms /tmp/rpm_urls.txt

echo "Bazzite kernel installed"