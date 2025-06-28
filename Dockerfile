ARG FEDORA_VERSION="${FEDORA_VERSION:-42}"
ARG KERNEL_FLAVOR="${KERNEL_FLAVOR:-bazzite}"
ARG KERNEL_VERSION="${KERNEL_VERSION:-6.14.6-109.bazzite.fc42.x86_64}"

# Get Bazzite kernel and akmods
FROM ghcr.io/ublue-os/akmods:${KERNEL_FLAVOR}-${FEDORA_VERSION}-${KERNEL_VERSION} AS bazzite-akmods
FROM ghcr.io/ublue-os/akmods-extra:${KERNEL_FLAVOR}-${FEDORA_VERSION}-${KERNEL_VERSION} AS bazzite-akmods-extra

# Stage 1: context for scripts (not included in final image)
FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION} AS ctx
COPY build_files/ /ctx/
COPY soltros.pub /ctx/soltros.pub

# Change perms
RUN chmod +x \
    /ctx/bazzite-gaming.sh \
    /ctx/bazzite-kernel.sh \
    /ctx/cinnamon-desktop.sh \
    /ctx/cleanup.sh \
    /ctx/desktop-defaults.sh \
    /ctx/desktop-packages.sh \
    /ctx/gaming.sh \
    /ctx/overrides.sh \
    /ctx/repo-setup.sh \
    /ctx/signing.sh \
    /ctx/build.sh \
    /ctx/waterfox-installer.sh
# Main build - clean Fedora base
FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION} AS soltros

LABEL org.opencontainers.image.title="SoltrOS" \
    org.opencontainers.image.description="Gaming-ready Fedora with Cinnamon and MacBook support" \
    org.opencontainers.image.vendor="Soltros" \
    org.opencontainers.image.version="42"

# Copy system configurations
COPY system_files/etc /etc
COPY system_files/usr/share /usr/share

# Mount and run build script from ctx stage
ARG BASE_IMAGE
RUN --mount=type=bind,from=ctx,source=/ctx,target=/ctx \
    --mount=type=bind,from=bazzite-akmods,src=/kernel-rpms,dst=/tmp/kernel-rpms \
    --mount=type=bind,from=bazzite-akmods,src=/rpms,dst=/tmp/akmods-rpms \
    --mount=type=bind,from=bazzite-akmods-extra,src=/rpms,dst=/tmp/akmods-extra-rpms \
    --mount=type=tmpfs,dst=/tmp \
    BASE_IMAGE=$BASE_IMAGE bash /ctx/build.sh