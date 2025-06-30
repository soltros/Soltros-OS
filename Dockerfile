# Set base image and tag
ARG BASE_IMAGE=quay.io/fedora/fedora-bootc
ARG TAG_VERSION=latest
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
    /ctx/Budgie-desktop.sh \
    /ctx/build-initramfs.sh \
    /ctx/lightdm-fix.sh \
    /ctx/desktop-defaults.sh 

# Stage 2: final image
FROM ${BASE_IMAGE}:${TAG_VERSION} AS soltros

LABEL org.opencontainers.image.title="SoltrOS Desktop" \
    org.opencontainers.image.description="Gaming-ready Fedora CoreOS image with MacBook support" \
    org.opencontainers.image.vendor="Derrik" \
    org.opencontainers.image.version="42"

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

# Install dnf5 plugins and setup CachyOS kernel repo
RUN dnf5 -y install dnf5-plugins
RUN dnf5 -y config-manager setopt "*cachyos*".priority=1

# Remove default kernel packages and install CachyOS kernel
RUN dnf5 -y remove --no-autoremove kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra || true && \
    echo "Installing CachyOS kernel..." && \
    if dnf5 -y install kernel-cachyos; then \
        echo "CachyOS kernel installed successfully"; \
        echo "Installed CachyOS kernel packages:"; \
        dnf5 list installed | grep cachyos || true; \
    else \
        echo "Failed to install kernel-cachyos, trying LTS version..."; \
        if dnf5 -y install kernel-cachyos-lts; then \
            echo "CachyOS LTS kernel installed successfully"; \
        else \
            echo "All CachyOS kernel installation attempts failed"; \
            echo "Available CachyOS packages:"; \
            dnf5 search kernel-cachyos || true; \
            echo "Falling back to default kernel installation"; \
            dnf5 -y install kernel kernel-core kernel-modules || true; \
        fi; \
    fi && \
    echo "Final kernel verification:" && \
    dnf5 list installed | grep -E "(kernel|cachyos)" || true && \
    echo "Available kernel modules:" && \
    ls -la /usr/lib/modules/ || true

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

# Mount and run build script from ctx stage
ARG BASE_IMAGE
ENV KERNEL_FLAVOR=cachyos
RUN --mount=type=bind,from=ctx,source=/ctx,target=/ctx \
    --mount=type=tmpfs,dst=/tmp \
    BASE_IMAGE=$BASE_IMAGE bash /ctx/build.sh