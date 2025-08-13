# Set base image and tag
ARG BASE_IMAGE=quay.io/fedora-ostree-desktops/base-atomic
ARG TAG_VERSION=42
FROM ${BASE_IMAGE}:${TAG_VERSION}

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
    /ctx/nix-package-manager.sh \
    /ctx/desktop-defaults.sh

# Stage 2: final image
FROM ${BASE_IMAGE}:${TAG_VERSION} AS soltros

# EXPLICIT DISTRO LABELS FOR BOOTC-IMAGE-BUILDER
# These override any conflicting labels and force correct distro detection
LABEL ostree.linux="alma" \
    org.opencontainers.image.version="10" \
    distro.name="alma" \
    distro.version="10"

# Your custom branding (these won't interfere)
LABEL org.opencontainers.image.title="SoltrOS Workstation Desktop" \
    org.opencontainers.image.description="Workstation and Development image that also supports gaming" \
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

# Get rid of Plymouth
RUN dnf5 remove plymouth* -y && \
    systemctl disable plymouth-start.service plymouth-read-write.service plymouth-quit.service plymouth-quit-wait.service plymouth-reboot.service plymouth-kexec.service plymouth-halt.service plymouth-poweroff.service 2>/dev/null || true && \
    rm -rf /usr/share/plymouth /usr/lib/plymouth /etc/plymouth && \
    rm -f /usr/lib/systemd/system/plymouth* /usr/lib/systemd/system/*/plymouth* && \
    rm -f /usr/bin/plymouth /usr/sbin/plymouthd && \
    sed -i 's/rhgb quiet//' /etc/default/grub 2>/dev/null || true && \
    sed -i 's/splash//' /etc/default/grub 2>/dev/null || true && \
    sed -i '/plymouth/d' /etc/dracut.conf.d/* 2>/dev/null || true && \
    echo 'omit_dracutmodules+=" plymouth "' > /etc/dracut.conf.d/99-disable-plymouth.conf && \
    grub2-mkconfig -o /boot/grub2/grub.cfg 2>/dev/null || true && \
    dracut -f 2>/dev/null || true && \
    dnf5 autoremove -y && \
    dnf5 clean all

# Mount and run build script from ctx stage
ARG BASE_IMAGE
RUN --mount=type=bind,from=ctx,source=/ctx,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    BASE_IMAGE=$BASE_IMAGE bash /ctx/build.sh

# Ensure bootc compatibility
RUN ostree container commit
