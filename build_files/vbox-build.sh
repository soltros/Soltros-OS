#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Building VirtualBox kernel modules for immutable system"

# Get the kernel version that will be used in the final image
KERNEL_VERSION=$(rpm -q kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}\n' | head -1)
log "Target kernel version: $KERNEL_VERSION"

# Ensure we have the exact kernel-devel for the target kernel
log "Installing kernel development packages for $KERNEL_VERSION"
dnf5 install -y kernel-devel kernel-headers

# Also install build dependencies
log "Installing VirtualBox build dependencies"
dnf5 install -y \
    gcc \
    make \
    perl \
    elfutils-libelf-devel \
    dkms

log "Building VirtualBox kernel modules"

# Set the kernel source directory
export KERN_DIR="/usr/src/kernels/${KERNEL_VERSION}"
export KERN_VER="${KERNEL_VERSION}"

# Verify kernel source exists
if [ ! -d "$KERN_DIR" ]; then
    log "Error: Kernel source directory not found at $KERN_DIR"
    log "Available kernel sources:"
    ls -la /usr/src/kernels/ || true
    exit 1
fi

log "Using kernel source directory: $KERN_DIR"

# Run vboxconfig to build the modules
log "Running vboxconfig to build kernel modules"
/sbin/vboxconfig

# Verify modules were built
log "Checking if VirtualBox modules were built successfully"
MODULES_DIR="/lib/modules/${KERNEL_VERSION}/misc"
for module in vboxdrv vboxnetflt vboxnetadp vboxpci; do
    if [ -f "${MODULES_DIR}/${module}.ko" ]; then
        log "✓ Module ${module}.ko built successfully"
    else
        log "✗ Module ${module}.ko not found"
    fi
done

# Create module loading configuration
log "Setting up module loading configuration"
cat > /etc/modules-load.d/virtualbox.conf << 'EOF'
# VirtualBox kernel modules
vboxdrv
vboxnetflt
vboxnetadp
vboxpci
EOF

# Create udev rules for VirtualBox
log "Setting up VirtualBox udev rules"
cat > /etc/udev/rules.d/60-vboxdrv.rules << 'EOF'
# VirtualBox device permissions
KERNEL=="vboxdrv", OWNER="root", GROUP="vboxusers", MODE="0660"
KERNEL=="vboxnetctl", OWNER="root", GROUP="vboxusers", MODE="0660"
SUBSYSTEM=="usb_device", ACTION=="add", RUN+="/usr/share/virtualbox/VBoxCreateUSBNode.sh $major $minor $attr{bDeviceClass}"
SUBSYSTEM=="usb", ACTION=="add", ENV{DEVTYPE}=="usb_device", RUN+="/usr/share/virtualbox/VBoxCreateUSBNode.sh $major $minor $attr{bDeviceClass}"
SUBSYSTEM=="usb_device", ACTION=="remove", RUN+="/usr/share/virtualbox/VBoxCreateUSBNode.sh --remove $major $minor"
SUBSYSTEM=="usb", ACTION=="remove", ENV{DEVTYPE}=="usb_device", RUN+="/usr/share/virtualbox/VBoxCreateUSBNode.sh --remove $major $minor"
EOF

# Create vboxusers group (this will be in the image)
log "Creating vboxusers group"
groupadd -f vboxusers

# Enable VirtualBox service
log "Enabling VirtualBox driver service"
systemctl enable vboxdrv.service || true

# Create a justfile for VirtualBox user management
log "Setting up VirtualBox just commands"
cat > /usr/share/ublue-os/just/70-virtualbox.just << 'EOF'
# VirtualBox management commands

# Add current user to vboxusers group (requires logout/login)
add-to-vboxusers:
    sudo usermod -aG vboxusers $USER
    @echo "User added to vboxusers group. Please log out and back in for changes to take effect."

# Check VirtualBox module status
check-vbox-modules:
    @echo "Checking VirtualBox kernel modules:"
    @lsmod | grep vbox || echo "No VirtualBox modules loaded"
    @echo ""
    @echo "VirtualBox driver service status:"
    @systemctl status vboxdrv --no-pager || true

# Restart VirtualBox driver service
restart-vboxdrv:
    sudo systemctl restart vboxdrv
EOF

# Update depmod for the new modules
log "Updating module dependencies"
depmod -a ${KERNEL_VERSION}

log "VirtualBox kernel modules build complete"
log "Modules should be loaded automatically on boot"
log "Users can run 'just add-to-vboxusers' to get VirtualBox access"
