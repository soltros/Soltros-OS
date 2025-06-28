#!/bin/bash
set ${SET_X:+-x} -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Applying gaming optimizations"

log "Setting up gaming-specific sysctl parameters"
cat > /etc/sysctl.d/99-gaming.conf << 'EOF'
# Gaming optimizations for better performance

# Increase memory map areas for games (especially needed for newer games)
vm.max_map_count = 2147483642

# Increase file descriptor limits for gaming applications
fs.file-max = 2097152

# Network optimizations for online gaming
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216

# Reduce swappiness for gaming performance (keep things in RAM)
vm.swappiness = 1

# Optimize dirty page writeback for gaming workloads
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

log "Setting up CPU governor optimization for gaming"
cat > /etc/tmpfiles.d/gaming-cpu.conf << 'EOF'
# Set CPU governor to performance mode for gaming
# This will be applied at boot

w /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor - - - - performance
EOF

log "Gaming optimizations applied successfully"
