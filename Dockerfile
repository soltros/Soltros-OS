# ---------- Build args ----------
ARG BASE_IMAGE=quay.io/almalinuxorg/atomic-desktop-kde
ARG TAG_VERSION=10

# ---------- Stage: ctx (scripts only) ----------
FROM ${BASE_IMAGE}:${TAG_VERSION} AS ctx
COPY build_files/ /ctx/
COPY soltros.pub /ctx/soltros.pub
COPY soltros.pub /etc/pki/containers/soltros.pub
RUN chmod 644 /etc/pki/containers/soltros.pub \
 && chmod +x \
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

# ---------- Stage: final image ----------
FROM ${BASE_IMAGE}:${TAG_VERSION} AS soltros

# Force correct distro detection for bootc-image-builder
LABEL ostree.linux="alma" \
      org.opencontainers.image.version="10" \
      distro.name="alma" \
      distro.version="10"

# Branding
LABEL org.opencontainers.image.title="SoltrOS Desktop LTS" \
      org.opencontainers.image.description="Gaming-ready, stable Atomic KDE image with MacBook support" \
      org.opencontainers.image.vendor="Derrik"

# 1) Start clean: remove any repos shipped by the base image to avoid duplicates
RUN rm -f /etc/yum.repos.d/*.repo

# 2) Copy your system files (includes your repo *.repo files and os-release)
COPY system_files/etc /etc
COPY system_files/usr /usr


# 4) Make DNF resilient and fast
RUN printf '%s\n' \
  'max_parallel_downloads=10' \
  'retries=10' \
  'timeout=60' \
  'fastestmirror=True' \
  'skip_if_unavailable=True' \
  >> /etc/dnf/dnf.conf

# 5) Sanity-check repos & warm cache early (helps fail fast if a key/url is wrong)
RUN dnf -y makecache && dnf repolist -v

# Shell config dirs (harmless if already present)
RUN mkdir -p /etc/profile.d /etc/fish/conf.d

# EPEL + RPM Fusion + Terra repos
ARG EL_MAJOR=10
RUN set -eux; \
    dnf -y install \
      "https://dl.fedoraproject.org/pub/epel/epel-release-latest-${EL_MAJOR}.noarch.rpm" \
      "https://download1.rpmfusion.org/free/el/rpmfusion-free-release-${EL_MAJOR}.noarch.rpm" \
      "https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-${EL_MAJOR}.noarch.rpm" \
      "https://repo.terralinux.org/terra/terra-release-latest-${EL_MAJOR}.noarch.rpm"; \
    dnf -y clean all


# Distrobox (EPEL provides it per your repos)
RUN dnf -y install distrobox && dnf -y clean all

# Tailscale repo + install (EL10)
RUN dnf -y install dnf-plugins-core \
 && dnf config-manager --add-repo https://pkgs.tailscale.com/stable/rhel/10/tailscale.repo \
 && dnf -y install tailscale \
 && dnf -y clean all

# SELinux tooling (for relabel & policy utilities)
RUN dnf -y install \
      selinux-policy \
      selinux-policy-targeted \
      policycoreutils \
      policycoreutils-python-utils \
      libselinux-utils \
      checkpolicy \
      setools-console \
 && dnf -y clean all

# Run your build script from ctx
ARG BASE_IMAGE
RUN --mount=type=bind,from=ctx,source=/ctx,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    BASE_IMAGE=$BASE_IMAGE bash /ctx/build.sh

# Bootable/bootc labels + ostree commit
LABEL containers.bootc="1" \
      ostree.bootable="1"
RUN ostree container commit
