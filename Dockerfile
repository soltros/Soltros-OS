# Set base image and tag
ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite
ARG TAG_VERSION=stable
FROM ${BASE_IMAGE}:${TAG_VERSION}

# Stage 1: context for scripts (not included in final image)
FROM ${BASE_IMAGE}:${TAG_VERSION} AS ctx
COPY build_files/ /ctx/
COPY soltros.pub /ctx/soltros.pub

# Change perms
RUN chmod +x \
    /ctx/build.sh \
    /ctx/signing.sh \
    /ctx/overrides.sh \
    /ctx/cleanup.sh \
    /ctx/desktop-packages.sh \
    /ctx/gaming.sh \
    /ctx/waterfox-installer.sh \
   /ctx/desktop-defaults.sh

# Stage 2: final image
FROM ${BASE_IMAGE}:${TAG_VERSION} AS soltros

LABEL org.opencontainers.image.title="SoltrOS" \
    org.opencontainers.image.description="Gaming-ready Fedora CoreOS image with MacBook support" \
    org.opencontainers.image.vendor="Derrik" \
    org.opencontainers.image.version="42"

# Copy static system configuration and branding
COPY system_files/etc /etc
COPY system_files/usr/share /usr/share
COPY repo_files/tailscale.repo /etc/yum.repos.d/tailscale.repo
COPY resources/soltros-gdm.png /usr/share/pixmaps/fedora-gdm-logo.png
COPY resources/soltros-watermark.png /usr/share/plymouth/themes/spinner/watermark.png
# Create necessary directories for shell configurations
RUN mkdir -p /etc/profile.d /etc/fish/conf.d

RUN dnf5 remove plasma-desktop plasma-workspace plasma-* kde-* -y && \
    dnf5 remove $(rpm -qa | grep -E "^(plasma|kde)" | grep -v kf6) -y && \
    dnf5 autoremove -y

RUN dnf5 group install --skip-broken "budgie-desktop" -y
RUN dnf5 group install --skip-broken "budgie-desktop-apps" -y

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

# Enable Tailscale
RUN ln -sf /usr/lib/systemd/system/tailscaled.service /etc/systemd/system/multi-user.target.wants/tailscaled.service

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
