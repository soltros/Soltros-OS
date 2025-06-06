# Set base image and tag
ARG BASE_IMAGE=ghcr.io/ublue-os/aurora-dx
ARG TAG_VERSION=latest

# Stage 1: context for scripts (not included in final image)
FROM ${BASE_IMAGE}:${TAG_VERSION} AS ctx
COPY build_files/ /ctx/
COPY soltros.pub /ctx/soltros.pub

# Disable SELinux for Nix compatibility
RUN if [ -f /etc/selinux/config ]; then \
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config && \
        setenforce 0 || true; \
    fi

# Change perms
RUN chmod +x \
  /ctx/build.sh \
  /ctx/signing.sh \
  /ctx/overrides.sh \
  /ctx/cleanup.sh \
  /ctx/gaming-optimizations.sh \
  /ctx/desktop-packages.sh \
  /ctx/just-files.sh \
  /ctx/desktop-defaults.sh \
  /ctx/setup-just.sh

# Stage 2: final image
FROM ${BASE_IMAGE}:${TAG_VERSION} AS soltros

LABEL org.opencontainers.image.title="SoltrOS" \
      org.opencontainers.image.description="Gaming-ready Bluefin image with MacBook support" \
      org.opencontainers.image.vendor="Derrik" \
      org.opencontainers.image.version="42"

# Copy static system configuration and branding
COPY system_files/etc /etc
COPY system_files/usr/share /usr/share
COPY repo_files/tailscale.repo /etc/yum.repos.d/tailscale.repo

# Create necessary directories for shell configurations
RUN mkdir -p /etc/profile.d /etc/fish/conf.d

# Add RPM Fusion repos by copy to eliminate rate limiting
COPY repo_files/rpmfusion-free.repo /etc/yum.repos.d/rpmfusion-free.repo
COPY repo_files/rpmfusion-free-updates.repo /etc/yum.repos.d/rpmfusion-free-updates.repo
COPY repo_files/rpmfusion-free-updates-testing.repo /etc/yum.repos.d/rpmfusion-free-updates-testing.repo
COPY repo_files/rpmfusion-nonfree.repo /etc/yum.repos.d/rpmfusion-nonfree-nvidia-driver.repo
COPY repo_files/rpmfusion-nonfree-nvidia-driver.repo /etc/yum.repos.d/
COPY repo_files/rpmfusion-nonfree-steam.repo /etc/yum.repos.d/rpmfusion-nonfree-steam.repo
COPY repo_files/rpmfusion-nonfree-updates.repo /etc/yum.repos.d/rpmfusion-nonfree-updates.repo
COPY repo_files/rpmfusion-nonfree-updates-testing.repo /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo

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
    echo -e '\n\e[1;36mWelcome to SoltrOS — powered by Universal Blue\e[0m\n' > /etc/issue && \
    gtk-update-icon-cache -f /usr/share/icons/hicolor

# Mount and run build script from ctx stage
ARG BASE_IMAGE
RUN --mount=type=bind,from=ctx,source=/ctx,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    BASE_IMAGE=$BASE_IMAGE bash /ctx/build.sh
