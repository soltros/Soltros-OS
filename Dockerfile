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
    /ctx/signing.sh \
    /ctx/build.sh \
    /ctx/build-initramfs.sh \
    /ctx/waterfox-installer.sh

# Stage 2: Repository setup stage - separate from ctx
FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION} AS repo-setup

# Setup Copr repos
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    mkdir -p /var/roothome && \
    dnf5 -y install dnf5-plugins && \
    for copr in \
        bazzite-org/bazzite \
        bazzite-org/bazzite-multilib \
        ublue-os/staging \
        ublue-os/packages \
        bazzite-org/LatencyFleX \
        bazzite-org/obs-vkcapture \
        ycollet/audinux \
        bazzite-org/rom-properties \
        bazzite-org/webapp-manager \
        hhd-dev/hhd \
        che/nerd-fonts \
        hikariknight/looking-glass-kvmfr \
        mavit/discover-overlay \
        rok/cdemu \
        lizardbyte/beta; \
    do \
        echo "Enabling copr: $copr"; \
        dnf5 -y copr enable $copr; \
        dnf5 -y config-manager setopt copr:copr.fedorainfracloud.org:${copr////:}.priority=98 ;\
    done && unset -v copr && \
    dnf5 -y install --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release{,-extras} && \
    dnf5 -y config-manager addrepo --overwrite --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo && \
    dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
    sed -i 's@enabled=0@enabled=1@g' /etc/yum.repos.d/negativo17-fedora-multimedia.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-steam.repo && \
    dnf5 -y config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-rar.repo && \
    dnf5 -y config-manager setopt "*bazzite*".priority=1 && \
    dnf5 -y config-manager setopt "*akmods*".priority=2 && \
    dnf5 -y config-manager setopt "*terra*".priority=3 "*terra*".exclude="nerd-fonts topgrade" && \
    dnf5 -y config-manager setopt "terra-mesa".enabled=true && \
    dnf5 -y config-manager setopt "terra-nvidia".enabled=false && \
    eval "$(/ctx/dnf5-setopt setopt '*negativo17*' priority=4 exclude='mesa-* *xone*')" && \
    dnf5 -y config-manager setopt "*rpmfusion*".priority=5 "*rpmfusion*".exclude="mesa-*" && \
    dnf5 -y config-manager setopt "*fedora*".exclude="mesa-* kernel-core-* kernel-modules-* kernel-uki-virt-*" && \
    dnf5 -y config-manager setopt "*staging*".exclude="scx-scheds kf6-* mesa* mutter* rpm-ostree* systemd* gnome-shell gnome-settings-daemon gnome-control-center gnome-software libadwaita tuned*" && \
    /ctx/cleanup

# Main build - clean Fedora base
FROM quay.io/fedora/fedora-bootc:${FEDORA_VERSION} AS soltros

LABEL org.opencontainers.image.title="SoltrOS" \
    org.opencontainers.image.description="Gaming-ready Fedora with Cinnamon and MacBook support" \
    org.opencontainers.image.vendor="Soltros" \
    org.opencontainers.image.version="42"

# Copy system configurations
COPY system_files/etc /etc
COPY system_files/usr/share /usr/share

# Copy repository setup from previous stage
COPY --from=repo-setup /etc/yum.repos.d/ /etc/yum.repos.d/
COPY --from=repo-setup /etc/pki/rpm-gpg/ /etc/pki/rpm-gpg/

# Mount and run build script from ctx stage
ARG BASE_IMAGE
RUN --mount=type=bind,from=ctx,source=/ctx,target=/ctx \
    --mount=type=bind,from=bazzite-akmods,src=/kernel-rpms,dst=/tmp/kernel-rpms \
    --mount=type=bind,from=bazzite-akmods,src=/rpms,dst=/tmp/akmods-rpms \
    --mount=type=bind,from=bazzite-akmods-extra,src=/rpms,dst=/tmp/akmods-extra-rpms \
    --mount=type=tmpfs,dst=/tmp \
    BASE_IMAGE=$BASE_IMAGE bash /ctx/build.sh