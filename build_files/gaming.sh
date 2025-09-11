#!/usr/bin/bash
set ${SET_X:+-x} -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Applying gaming optimizations"

log "Disabling irqbalance service for reduced latency"
# irqbalance can sometimes interfere with latency-sensitive applications by moving
# interrupt handlers between CPU cores. Disabling it can provide more predictable
# performance for gaming.
systemctl disable --now irqbalance.service || true

log "Setting up gaming-specific sysctl parameters"
cat > /etc/sysctl.d/99-gaming.conf << 'EOF'
# Gaming optimizations for better performance

# Increase memory map areas for games (especially needed for newer games)
# A larger mmap count allows applications to handle more memory-mapped files,
# which can be crucial for modern games.
vm.max_map_count = 2147483642

# Increase file descriptor limits for gaming applications
# Games often open many files (textures, audio, etc.). This prevents "too many open files" errors.
fs.file-max = 2097152

# Network optimizations for online gaming
# These settings increase the default and maximum socket buffer sizes, which can
# improve performance and reduce packet loss in high-latency network scenarios.
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216

# Reduce swappiness for gaming performance (keep things in RAM)
# A swappiness of 1 tells the kernel to avoid swapping unless absolutely necessary,
# keeping game data in fast RAM instead of slow disk space.
vm.swappiness = 1

# Optimize dirty page writeback for gaming workloads
# These values control when the kernel writes "dirty" data from memory to disk.
# Lowering them can help prevent stuttering caused by background I/O operations.
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF

log "Setting up gaming udev rules for controller access"
cat > /etc/udev/rules.d/99-gaming-devices.rules << 'EOF'
# Gaming controller access rules

# PlayStation controllers (PS3, PS4, PS5)
SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*054c*", MODE="0666", TAG+="uaccess"

# Xbox controllers (Xbox One, Series X/S)
SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*045e*", MODE="0666", TAG+="uaccess"

# Nintendo Switch Pro Controller
SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*057e*", MODE="0666", TAG+="uaccess"

# Steam Controller
SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*28de*", MODE="0666", TAG+="uaccess"

# 8BitDo controllers
SUBSYSTEM=="usb", ATTRS{idVendor}=="2dc8", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*2dc8*", MODE="0666", TAG+="uaccess"
EOF

log "Setting up gaming-specific environment variables"
cat > /etc/profile.d/gaming.sh << 'EOF'
# Gaming environment optimizations

# Enable Steam native runtime by default (better compatibility)
export STEAM_RUNTIME_PREFER_HOST_LIBRARIES=0

# Enable MangoHud for all Vulkan applications (if installed)
# export MANGOHUD=1

# Enable gamemode for supported applications
# export LD_PRELOAD="libgamemode.so.0:$LD_PRELOAD"

# Optimize for AMD GPUs (uncomment if using AMD)
# export RADV_PERFTEST=aco,llvm
# export AMD_VULKAN_ICD=RADV

# Optimize for NVIDIA GPUs (uncomment if using NVIDIA)
# export __GL_THREADED_OPTIMIZATIONS=1
# export __GL_SHADER_DISK_CACHE=1
EOF

log "Setting up gaming-specific modules to load"
cat > /etc/modules-load.d/gaming.conf << 'EOF'
# Gaming-related kernel modules

# Xbox controller support
xpad

# General HID support for gaming devices
uinput
EOF

log "Setting up CPU governor and I/O scheduler optimizations via tmpfiles.d"
# This is a robust way to ensure these settings are applied early at boot.
cat > /etc/tmpfiles.d/gaming-cpu-io.conf << 'EOF'
# Set CPU governor to performance mode
w /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor - - - - performance

# Set I/O scheduler to mq-deadline, which is optimized for SSDs
w /sys/block/sda/queue/scheduler - - - - mq-deadline
EOF

log "Increasing system-wide file descriptor limits"
# This change affects all users and services. The values are higher than the
# ones set by fs.file-max to ensure enough room for individual processes.
cat > /etc/security/limits.d/99-gaming.conf << 'EOF'
# Increase file descriptor limits for all users and processes
* soft nofile 524288
* hard nofile 1048576
EOF

log "Gaming optimizations applied successfully"
