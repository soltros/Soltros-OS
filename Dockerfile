# Set base image and tag
ARG BASE_IMAGE=quay.io/fedora-ostree-desktops/kinoite
ARG TAG_VERSION=42
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
    /ctx/kde-desktop.sh \
    /ctx/build-initramfs.sh \
    /ctx/enable-services.sh \
    /ctx/nix-package-manager.sh \
    /ctx/desktop-defaults.sh

# Stage 2: final image
FROM ${BASE_IMAGE}:${TAG_VERSION} AS soltros

# EXPLICIT DISTRO LABELS FOR BOOTC-IMAGE-BUILDER
# These override any conflicting labels and force correct distro detection
LABEL ostree.linux="fedora" \
    org.opencontainers.image.version="42" \
    distro.name="fedora" \
    distro.version="42"

# Your custom branding (these won't interfere)
LABEL org.opencontainers.image.title="SoltrOS Desktop" \
    org.opencontainers.image.description="Gaming-ready, rolling Atomic KDE image with MacBook support" \
    org.opencontainers.image.vendor="Derrik"

# Copy static system configuration and branding
COPY system_files/etc /etc
COPY system_files/usr /usr
COPY repo_files/ /etc/yum.repos.d/
COPY resources/soltros-gdm.png /usr/share/pixmaps/fedora-gdm-logo.png
COPY resources/soltros-watermark.png /usr/share/plymouth/themes/spinner/watermark.png

# Create necessary directories for shell configurations
RUN mkdir -p /etc/profile.d /etc/fish/conf.d

# Ensure Distrobox is installed
RUN dnf5 install -y distrobox

# Install dnf5 plugins
RUN dnf5 -y install dnf5-plugins


# Add Terra repo separately with better error handling
RUN for i in {1..3}; do \
    curl --retry 3 --retry-delay 5 -Lo /etc/yum.repos.d/terra.repo https://terra.fyralabs.com/terra.repo && \
    break || sleep 10; \
    done

# Mount and run build script from ctx stage
ARG BASE_IMAGE
RUN --mount=type=bind,from=ctx,source=/ctx,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    BASE_IMAGE=$BASE_IMAGE bash /ctx/build.sh

# Ensure bootc compatibility
RUN ostree container commit

