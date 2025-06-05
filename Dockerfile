# Set base image and tag
ARG BASE_IMAGE=ghcr.io/ublue-os/bluefin
ARG TAG_VERSION=latest

# Stage 1: context for scripts (not included in final image)
FROM ${BASE_IMAGE}:${TAG_VERSION} AS ctx
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

LABEL org.opencontainers.image.title="SoltrOS" \
      org.opencontainers.image.description="Vanilla GNOME, gaming-ready Bluefin image with MacBook support" \
      org.opencontainers.image.vendor="Derrik" \
      org.opencontainers.image.version="42"

# Copy static system configuration and branding
COPY system_files/etc /etc
COPY system_files/usr/share /usr/share
COPY tailscale.repo /etc/yum.repos.d/tailscale.repo

# Create necessary directories for shell configurations
RUN mkdir -p /etc/profile.d /etc/fish/conf.d

# Create soltros-just wrapper and set up aliases
RUN echo -e '#!/bin/bash\nexec just --justfile /usr/share/soltros/just/justfile "$@"' > /usr/local/bin/soltros-just && \
    chmod +x /usr/local/bin/soltros-just && \
    echo 'alias just="soltros-just"' > /etc/profile.d/soltros-just.sh && \
    echo 'alias just="soltros-just"' > /etc/fish/conf.d/soltros-just.fish

# Add external repos (RPM Fusion, Terra) with better error handling
RUN rpm-ostree install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm && \
    for i in {1..3}; do \
        rpm-ostree install \
            https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
        break || sleep 10; \
    done

# Add Terra repo separately with better error handling
RUN for i in {1..3}; do \
        curl --retry 3 --retry-delay 5 -Lo /etc/yum.repos.d/terra.repo https://terra.fyralabs.com/terra.repo && \
        break || sleep 10; \
    done

# Set identity and system branding with better error handling
RUN for i in {1..3}; do \
        curl --retry 3 --retry-delay 5 -Lo /usr/lib/os-release https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/os-release && \
        break || sleep 10; \
    done && \
    for i in {1..3}; do \
        curl --retry 3 --retry-delay 5 -Lo /etc/motd https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/motd && \
        break || sleep 10; \
    done && \
    for i in {1..3}; do \
        curl --retry 3 --retry-delay 5 -Lo /etc/dconf/db/local.d/00-soltros-settings https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/00-soltros-settings && \
        break || sleep 10; \
    done && \
    dconf update && \
    echo -e '\n\e[1;36mWelcome to SoltrOS — powered by Fedora Silverblue\e[0m\n' > /etc/issue && \
    gtk-update-icon-cache -f /usr/share/icons/hicolor

# Mount and run build script from ctx stage
ARG BASE_IMAGE
RUN --mount=type=bind,from=ctx,source=/ctx,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    BASE_IMAGE=$BASE_IMAGE bash /ctx/build.sh
