# Set base image and tag
ARG BASE_IMAGE=ghcr.io/ublue-os/bluefin
ARG TAG_VERSION=latest

# Stage 1: context for scripts (not included in final image)
FROM scratch AS ctx
COPY build_files/ /ctx/
COPY cosign.pub /ctx/cosign.pub

# Change perms
RUN chmod +x \
  /ctx/build.sh \
  /ctx/server-packages.sh \
  /ctx/signing.sh \
  /ctx/overrides.sh \
  /ctx/cleanup.sh \
  /ctx/desktop-packages.sh \
  /ctx/just-files.sh \
  /ctx/desktop-defaults.sh


# Stage 2: final image
FROM ${BASE_IMAGE}:${TAG_VERSION} AS soltros

LABEL org.opencontainers.image.title="SoltrOS"
LABEL org.opencontainers.image.description="Vanilla GNOME, gaming-ready Bluefin image with MacBook support"
LABEL org.opencontainers.image.vendor="Derrik"
LABEL org.opencontainers.image.version="42"

# Copy static system configuration and branding
COPY system_files/etc /etc
COPY system_files/usr/share /usr/share
COPY tailscale.repo /etc/yum.repos.d/tailscale.repo

# Add external repos (RPM Fusion, Terra)
RUN rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    curl -Lo /etc/yum.repos.d/terra.repo https://terra.fyralabs.com/terra.repo

# Set identity and system branding
RUN curl -Lo /usr/lib/os-release https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/os-release && \
    curl -Lo /etc/motd https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/motd && \
    curl -Lo /etc/dconf/db/local.d/00-soltros-settings https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/00-soltros-settings && \
    dconf update && \
    echo -e '\n\e[1;36mWelcome to SoltrOS — powered by Fedora Silverblue\e[0m\n' > /etc/issue && \
    gtk-update-icon-cache -f /usr/share/icons/hicolor

# Mount and run build script from ctx stage
ARG BASE_IMAGE
RUN --mount=type=bind,from=ctx,source=/ctx,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    BASE_IMAGE=$BASE_IMAGE bash /ctx/build.sh

LABEL org.opencontainers.image.title="SoltrOS" \
      org.opencontainers.image.description="Gaming-tuned, minimal Fedora-based GNOME image with Waterfox and RPMFusion apps"

