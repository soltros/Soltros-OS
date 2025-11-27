# Set base image and tag
ARG BASE_IMAGE=quay.io/fedora-ostree-desktops/base-atomic
ARG TAG_VERSION=rawhide
FROM ${BASE_IMAGE}:${TAG_VERSION}
RUN awk -F= '/^NAME=|^VERSION_ID=/{gsub(/"/,"");print}' /etc/os-release
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}" \
      org.opencontainers.image.version="${TAG_VERSION}" \
      ostree.linux="fedora"

# Stage 1: context for scripts (not included in final image)
FROM ${BASE_IMAGE}:${TAG_VERSION} AS ctx
COPY build_files/ /ctx/
COPY soltros.pub /ctx/soltros.pub
COPY soltros.pub /etc/pki/containers/soltros.pub
RUN chmod 644 /etc/pki/containers/soltros.pub

# Change perms
RUN chmod +x \
    /ctx/build.sh \
    /ctx/signing.sh \
    /ctx/overrides.sh \
    /ctx/cleanup.sh \
    /ctx/desktop-packages.sh \
    /ctx/gaming.sh \
    /ctx/waterfox-installer.sh \
    /ctx/gnome-desktop.sh \
    /ctx/build-initramfs.sh \
    /ctx/enable-services.sh \
    /ctx/nix-package-manager.sh \
    /ctx/desktop-defaults.sh

# Stage 2: final image
FROM ${BASE_IMAGE}:${TAG_VERSION} AS soltros

# EXPLICIT DISTRO LABELS FOR BOOTC-IMAGE-BUILDER
# These override any conflicting labels and force correct distro detection
LABEL ostree.linux="fedora" \
    org.opencontainers.image.version="43" \
    distro.name="fedora" \
    distro.version="43"

# Your custom branding (these won't interfere)
LABEL org.opencontainers.image.title="SoltrOS Desktop" \
    org.opencontainers.image.description="Gaming-ready, rolling Atomic Gnome image with MacBook support" \
    org.opencontainers.image.vendor="Derrik"

# Copy static system configuration and branding
RUN rm -f /etc/containers/policy.json
COPY system_files/etc /etc
COPY system_files/usr /usr
COPY repo_files/ /etc/yum.repos.d/
COPY resources/soltros-gdm.png /usr/share/pixmaps/fedora-gdm-logo.png
COPY resources/fedora_whitelogo_med.png /usr/share/pixmaps/fedora_whitelogo_med.png

# Create necessary directories for shell configurations
RUN mkdir -p /etc/profile.d /etc/fish/conf.d

# Ensure Distrobox is installed
RUN dnf5 install -y distrobox

# Install dnf5 plugins
RUN dnf5 -y install dnf5-plugins

# Add Terra repo 
RUN dnf install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release

# Mount and run build script from ctx stage
ARG BASE_IMAGE
RUN --mount=type=bind,from=ctx,source=/ctx,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    BASE_IMAGE=$BASE_IMAGE bash /ctx/build.sh

# Ensure bootc compatibility
RUN ostree container commit

