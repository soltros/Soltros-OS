#!/usr/bin/bash
set -eoux pipefail
IMAGE_PRETTY_NAME="YourOS"
IMAGE_LIKE="fedora"
HOME_URL="https://youros.example.org"
DOCUMENTATION_URL="https://docs.yourosexample.org"
SUPPORT_URL="https://support.yourosexample.org"
BUG_SUPPORT_URL="https://github.com/youros/issues/"
LOGO_ICON="youros-logo"
LOGO_COLOR="0;38;2;138;43;226"
CODE_NAME="Nebula"
IMAGE_INFO="/usr/share/ublue-os/image-info.json"
FEDORA_VERSION=40
IMAGE_TAG="stable"
IMAGE_NAME="youros"
IMAGE_VENDOR="youros"
VERSION_TAG="v1"
VERSION_PRETTY="1.0"
cat > $IMAGE_INFO <<EOF
{
  "image-name": "$IMAGE_NAME",
  "image-flavor": "vanilla-gnome",
  "image-vendor": "$IMAGE_VENDOR",
  "image-ref": "ostree-image-signed:docker://ghcr.io/$IMAGE_VENDOR/$IMAGE_NAME",
  "image-tag": "$IMAGE_TAG",
  "image-branch": "stable",
  "base-image-name": "silverblue",
  "fedora-version": "$FEDORA_VERSION",
  "version": "$VERSION_TAG",
  "version-pretty": "$VERSION_PRETTY"
}
EOF
