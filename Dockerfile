ARG FEDORA_VERSION="${FEDORA_VERSION:-42}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-bazzite}"
ARG KERNEL_VERSION="${KERNEL_VERSION:-6.14.6-109.bazzite.fc42.x86_64}"

# Get Bazzite kernel and akmods
FROM ghcr.io/ublue-os/akmods:${KERNEL_FLAVOR}-${FEDORA_VERSION}-${KERNEL_VERSION} AS bazzite-akmods
FROM ghcr.io/ublue-os/akmods-extra:${KERNEL_FLAVOR}-${FEDORA_VERSION}-${KERNEL_VERSION} AS bazzite-akmods-extra


# Build context
FROM scratch AS ctx
COPY build_files/ /ctx/
COPY soltros.pub /ctx/soltros.pub
RUN chmod +x /ctx/*.sh

# Main build - clean Fedora base
FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION} AS soltros

LABEL org.opencontainers.image.title="SoltrOS" \
    org.opencontainers.image.description="Gaming-ready Fedora with Cinnamon and MacBook support" \
    org.opencontainers.image.vendor="Soltros" \
    org.opencontainers.image.version="42"

# Copy system configurations
COPY system_files/etc /etc
COPY system_files/usr/share /usr/share

# Setup repositories including Bazzite gaming repos
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/repo-setup.sh

# Install Bazzite kernel with gaming optimizations
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=bazzite-akmods,src=/kernel-rpms,dst=/tmp/kernel-rpms \
    --mount=type=bind,from=bazzite-akmods,src=/rpms,dst=/tmp/akmods-rpms \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/install-bazzite-kernel.sh

# Install Cinnamon desktop environment
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/cinnamon-desktop.sh

# Install gaming packages from Bazzite repos
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/bazzite-gaming.sh

# Core desktop packages
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/desktop-packages.sh

# MacBook hardware support
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/macbook-support.sh

# Install Waterfox
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/waterfox-installer.sh

# Container signing
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    /ctx/signing.sh

# Final cleanup and validation
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/cleanup.sh && \
    bootc container lint