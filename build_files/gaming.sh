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

# TCP optimizations for low-latency gaming
# Enable TCP fast open for reduced connection latency
net.ipv4.tcp_fastopen = 3
# Optimize TCP congestion control for gaming (BBR is excellent for real-time traffic)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
# Reduce TIME_WAIT socket timeout to free up resources faster
net.ipv4.tcp_fin_timeout = 15
# Increase the range of local ports available for connections
net.ipv4.ip_local_port_range = 1024 65535
# Enable TCP window scaling for better throughput
net.ipv4.tcp_window_scaling = 1
# Optimize TCP timestamps
net.ipv4.tcp_timestamps = 1
# Reduce TCP keepalive time for faster detection of dead connections
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# Reduce swappiness for gaming performance (keep things in RAM)
# A swappiness of 1 tells the kernel to avoid swapping unless absolutely necessary,
# keeping game data in fast RAM instead of slow disk space.
vm.swappiness = 1

# Optimize dirty page writeback for gaming workloads
# These values control when the kernel writes "dirty" data from memory to disk.
# Lowering them can help prevent stuttering caused by background I/O operations.
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Memory management optimizations
# Reduce memory compaction overhead which can cause micro-stutters
vm.compaction_proactiveness = 0
# Control how aggressively the kernel reclaims memory
vm.vfs_cache_pressure = 50
# Optimize page cache and inode/dentry cache balance
vm.min_free_kbytes = 65536

# Process scheduling optimizations
# Reduce latency for interactive tasks (gaming)
kernel.sched_latency_ns = 4000000
kernel.sched_min_granularity_ns = 500000
kernel.sched_wakeup_granularity_ns = 500000
# Prefer scheduling tasks on the same CPU for better cache locality
kernel.sched_migration_cost_ns = 5000000
# Autogroup scheduling helps prevent background tasks from affecting game performance
kernel.sched_autogroup_enabled = 1

# Disable NMI watchdog for reduced overhead and latency
# The NMI watchdog can cause small latency spikes; disabling it helps with consistent frame times
kernel.nmi_watchdog = 0

# Optimize transparent huge pages for gaming
# THP can improve memory performance by using larger page sizes
vm.transparent_hugepage_defrag = defer+madvise
vm.transparent_hugepage_enabled = madvise

# Audio/Real-time optimizations
# Increase the maximum percentage of system time that can be spent on real-time tasks
# This is crucial for low-latency audio in games
kernel.sched_rt_runtime_us = 980000
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

# Logitech controllers and wheels
SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*046d*", MODE="0666", TAG+="uaccess"

# VR Headsets
# Oculus Rift/Rift S/Quest
SUBSYSTEM=="usb", ATTRS{idVendor}=="2833", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*2833*", MODE="0666", TAG+="uaccess"

# HTC Vive/Vive Pro
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bb4", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*0bb4*", MODE="0666", TAG+="uaccess"

# Valve Index
SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2000", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2012", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="2101", MODE="0666", TAG+="uaccess"

# Razer peripherals (controllers, mice, keyboards)
SUBSYSTEM=="usb", ATTRS{idVendor}=="1532", MODE="0666", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNELS=="*1532*", MODE="0666", TAG+="uaccess"
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
# export mesa_glthread=true

# Optimize for NVIDIA GPUs (uncomment if using NVIDIA)
# export __GL_THREADED_OPTIMIZATIONS=1
# export __GL_SHADER_DISK_CACHE=1
# export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1

# Optimize for Intel GPUs (uncomment if using Intel)
# export ANV_ENABLE_PIPELINE_CACHE=1
# export INTEL_DEBUG=norbc

# Wine/Proton optimizations
export WINE_CPU_TOPOLOGY=4:0,1,2,3
export DXVK_HUD=compiler
# export DXVK_ASYNC=1  # Warning: May cause issues in some games with anti-cheat

# Enable PipeWire low-latency mode for gaming audio (if using PipeWire)
export PIPEWIRE_LATENCY=128/48000

# Vulkan optimizations
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json:/usr/share/vulkan/icd.d/nvidia_icd.json
export VK_LAYER_PATH=/usr/share/vulkan/explicit_layer.d

# Disable compositing hints for games (reduces input lag)
export __GL_YIELD="USLEEP"
export vblank_mode=0
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

# Set I/O scheduler to mq-deadline for SATA/SCSI devices (optimized for SSDs)
w /sys/block/sda/queue/scheduler - - - - mq-deadline
w /sys/block/sdb/queue/scheduler - - - - mq-deadline

# Set I/O scheduler to none for NVMe devices (they handle scheduling in hardware)
w /sys/block/nvme*/queue/scheduler - - - - none

# Reduce I/O queue depth for better latency
w /sys/block/*/queue/nr_requests - - - - 128

# Disable add_random for better performance (entropy generation can cause latency)
w /sys/block/*/queue/add_random - - - - 0

# Optimize read-ahead for gaming (8MB is good for loading game assets)
w /sys/block/*/queue/read_ahead_kb - - - - 8192

# Reduce rotational latency optimizations for SSDs
w /sys/block/*/queue/rotational - - - - 0

# Enable I/O statistics (useful for performance monitoring)
w /sys/block/*/queue/iostats - - - - 1

# PCI latency optimizations (reduce latency for GPU and storage)
w /sys/bus/pci/devices/*/latency_timer - - - - 0

# Disable power management for USB devices (prevents controller disconnects)
w /sys/bus/usb/devices/*/power/control - - - - on
w /sys/bus/usb/devices/*/power/autosuspend - - - - -1

# Disable CPU energy performance bias (prefer performance over power saving)
w /sys/devices/system/cpu/cpu*/power/energy_perf_bias - - - - 0
EOF

log "Increasing system-wide file descriptor limits"
# This change affects all users and services. The values are higher than the
# ones set by fs.file-max to ensure enough room for individual processes.
cat > /etc/security/limits.d/99-gaming.conf << 'EOF'
# Increase file descriptor limits for all users and processes
* soft nofile 524288
* hard nofile 1048576

# Increase memory lock limits for games that use large amounts of locked memory
* soft memlock unlimited
* hard memlock unlimited

# Increase priority limits (allows games to request higher priority)
* soft nice -20
* hard nice -20

# Increase real-time priority limits (crucial for low-latency audio and VR)
* soft rtprio 95
* hard rtprio 95
EOF

log "Setting up PipeWire real-time configuration for gaming audio"
# PipeWire provides low-latency audio which is crucial for gaming
mkdir -p /etc/pipewire/pipewire.conf.d
cat > /etc/pipewire/pipewire.conf.d/99-gaming-lowlatency.conf << 'EOF'
# Low-latency audio configuration for gaming
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 128
    default.clock.min-quantum = 64
    default.clock.max-quantum = 512
}
EOF

log "Setting up systemd service optimizations for gaming"
# Reduce journald overhead which can cause micro-stutters
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/gaming.conf << 'EOF'
[Journal]
# Reduce logging overhead
RateLimitBurst=1000
RateLimitIntervalSec=30s
# Store logs in memory for reduced disk I/O
Storage=volatile
# Limit journal size
RuntimeMaxUse=100M
EOF

# Optimize systemd for gaming workloads
mkdir -p /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/gaming.conf << 'EOF'
[Manager]
# Reduce default timeout values (faster boot)
DefaultTimeoutStartSec=10s
DefaultTimeoutStopSec=10s
# Disable core dumps (they can cause stuttering)
DefaultLimitCORE=0
# Increase file descriptor limits for all services
DefaultLimitNOFILE=1048576
# Set default nice level
DefaultLimitNICE=-20
EOF

log "Creating boot parameter recommendations file"
cat > /etc/gaming-boot-params.txt << 'EOF'
# Gaming-optimized kernel boot parameters
# Add these to your GRUB_CMDLINE_LINUX in /etc/default/grub and run grub2-mkconfig

# Disable CPU mitigations for better performance (reduces security, use at your own risk)
# mitigations=off

# Disable spectre/meltdown mitigations specifically (less aggressive than mitigations=off)
# nospectre_v1 nospectre_v2 spectre_v2=off spec_store_bypass_disable=off

# Set CPU governor to performance mode at boot
# cpufreq.default_governor=performance

# Disable watchdogs for lower latency
# nowatchdog nmi_watchdog=0

# Isolate CPUs for gaming (example: isolate cores 2-7 for games)
# isolcpus=2-7 nohz_full=2-7 rcu_nocbs=2-7

# Disable transparent huge pages defrag (reduce latency spikes)
# transparent_hugepage=madvise

# Optimize for low latency
# preempt=full threadirqs

# Disable audit system (reduces overhead)
# audit=0

# Increase PCI latency
# pci=noaer

# Example combined parameters:
# mitigations=off nowatchdog nmi_watchdog=0 cpufreq.default_governor=performance preempt=full audit=0
EOF

log "Setting up Transparent Huge Pages configuration"
# THP can significantly improve memory performance for games
cat > /etc/systemd/system/gaming-thp.service << 'EOF'
[Unit]
Description=Configure Transparent Huge Pages for Gaming
DefaultDependencies=no
After=sysinit.target local-fs.target
Before=basic.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo madvise > /sys/kernel/mm/transparent_hugepage/enabled'
ExecStart=/bin/bash -c 'echo defer+madvise > /sys/kernel/mm/transparent_hugepage/defrag'
ExecStart=/bin/bash -c 'echo 1 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag'
RemainAfterExit=yes

[Install]
WantedBy=basic.target
EOF

log "Enabling gaming THP service"
systemctl enable gaming-thp.service || true

log "Gaming optimizations applied successfully"
log "Note: Review /etc/gaming-boot-params.txt for additional kernel boot parameters"
log "      Some optimizations require a system reboot to take effect"
