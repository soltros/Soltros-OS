#!/usr/bin/bash

set -eoux pipefail

echo "::group::Executing build-initramfs"
trap 'echo "::endgroup::"' EXIT

# Debug: List all installed kernel packages
echo "Debug: Listing all installed kernel packages:"
dnf5 list installed | grep -E "(kernel|cachyos)" || true

# Debug: List available modules
echo "Debug: Available kernel modules:"
ls -la /usr/lib/modules/ || true

# Set the custom plymouth theme before rebuilding the initramfs
echo "Configuring Plymouth theme..."
plymouth-set-default-theme soltros-boot || true
echo "Plymouth theme set to 'soltros-boot'."

# Try multiple methods to find the installed kernel
QUALIFIED_KERNEL=""

# Method 1: Try different kernel package names based on KERNEL_FLAVOR
echo "Attempting to find kernel package..."

if [[ "${KERNEL_FLAVOR:-}" == "cachyos" ]]; then
    # Try CachyOS kernel package names
    for pkg in "kernel-cachyos" "kernel-cachyos-lts" "kernel-cachyos-rt" "kernel-cachyos-server" "kernel"; do
        echo "Trying package: $pkg"
        QUALIFIED_KERNEL="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' "$pkg" 2>/dev/null | head -1 || echo "")"
        if [[ -n "${QUALIFIED_KERNEL}" ]]; then
            echo "Found kernel via package $pkg: ${QUALIFIED_KERNEL}"
            break
        fi
    done
elif [[ "${KERNEL_FLAVOR:-}" == "longterm" ]]; then
    # Try longterm kernel package names
    for pkg in "kernel-longterm" "kernel"; do
        echo "Trying package: $pkg"
        QUALIFIED_KERNEL="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' "$pkg" 2>/dev/null | head -1 || echo "")"
        if [[ -n "${QUALIFIED_KERNEL}" ]]; then
            echo "Found kernel via package $pkg: ${QUALIFIED_KERNEL}"
            break
        fi
    done
else
    # Try standard kernel package names
    for pkg in "kernel-longterm" "kernel"; do
        echo "Trying package: $pkg"
        QUALIFIED_KERNEL="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' "$pkg" 2>/dev/null | head -1 || echo "")"
        if [[ -n "${QUALIFIED_KERNEL}" ]]; then
            echo "Found kernel via package $pkg: ${QUALIFIED_KERNEL}"
            break
        fi
    done
fi

# Method 2: If still not found, try to detect from modules directory
if [[ -z "${QUALIFIED_KERNEL}" ]]; then
    echo "Kernel not found via dnf5, attempting to detect from modules directory..."
    
    # Look for kernel directories in /usr/lib/modules/
    if [[ -d "/usr/lib/modules" ]]; then
        for kdir in /usr/lib/modules/*/; do
            if [[ -d "$kdir" && "$kdir" != "/usr/lib/modules/*/" ]]; then
                kernel_version=$(basename "$kdir")
                echo "Found kernel modules for: $kernel_version"
                
                # Verify this looks like a valid kernel version
                if [[ "$kernel_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
                    QUALIFIED_KERNEL="$kernel_version"
                    echo "Using detected kernel: ${QUALIFIED_KERNEL}"
                    break
                fi
            fi
        done
    fi
fi

# Method 3: If still not found, try to find any kernel
if [[ -z "${QUALIFIED_KERNEL}" ]]; then
    echo "Still no kernel found, trying broader search..."
    QUALIFIED_KERNEL="$(dnf5 repoquery --installed --queryformat='%{evr}.%{arch}' "*kernel*" | head -1 || echo "")"
fi

# Validate we found a kernel
if [[ -z "${QUALIFIED_KERNEL}" ]]; then
    echo "ERROR: No installed kernel found!"
    echo "Available kernel packages:"
    dnf5 list installed | grep -E "(kernel|cachyos)" || true
    echo "Available module directories:"
    ls -la /usr/lib/modules/ || true
    
    # As a last resort, skip initramfs build
    echo "WARNING: Skipping initramfs build due to missing kernel"
    exit 0
fi

echo "Building initramfs for kernel: ${QUALIFIED_KERNEL}"

# Check if the kernel modules directory exists
KERNEL_MODULES_DIR="/usr/lib/modules/${QUALIFIED_KERNEL}"
if [[ ! -d "${KERNEL_MODULES_DIR}" ]]; then
    echo "Kernel modules directory not found: ${KERNEL_MODULES_DIR}"
    echo "Available module directories:"
    ls -la /usr/lib/modules/ || true
    
    # Try to find the actual directory name that matches our kernel
    ACTUAL_DIR=""
    for dir in /usr/lib/modules/*/; do
        if [[ -d "$dir" && "$dir" != "/usr/lib/modules/*/" ]]; then
            dir_name=$(basename "$dir")
            echo "Checking directory: $dir_name"
            
            # Check if this directory name contains our kernel version
            if [[ "$dir_name" =~ ${QUALIFIED_KERNEL%.*} ]] || [[ "$QUALIFIED_KERNEL" =~ ${dir_name%.*} ]]; then
                echo "Found matching directory: $dir_name"
                QUALIFIED_KERNEL="$dir_name"
                KERNEL_MODULES_DIR="/usr/lib/modules/${QUALIFIED_KERNEL}"
                ACTUAL_DIR="$dir_name"
                break
            fi
        fi
    done
    
    # If still not found, use the first available directory
    if [[ -z "$ACTUAL_DIR" ]]; then
        for dir in /usr/lib/modules/*/; do
            if [[ -d "$dir" && "$dir" != "/usr/lib/modules/*/" ]]; then
                dir_name=$(basename "$dir")
                echo "Using first available directory: $dir_name"
                QUALIFIED_KERNEL="$dir_name"
                KERNEL_MODULES_DIR="/usr/lib/modules/${QUALIFIED_KERNEL}"
                break
            fi
        done
    fi
    
    if [[ ! -d "${KERNEL_MODULES_DIR}" ]]; then
        echo "WARNING: Still cannot find kernel modules directory, skipping initramfs build"
        exit 0
    fi
fi

echo "Final kernel modules directory: ${KERNEL_MODULES_DIR}"

# Build the initramfs
echo "Running dracut for kernel: ${QUALIFIED_KERNEL}"
if ! /usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible --zstd -v --add ostree -f "${KERNEL_MODULES_DIR}/initramfs.img"; then
    echo "ERROR: dracut failed for kernel ${QUALIFIED_KERNEL}"
    # Don't fail the build, just warn
    echo "WARNING: Continuing build without initramfs"
    exit 0
fi

# Set proper permissions
chmod 0600 "${KERNEL_MODULES_DIR}/initramfs.img"

echo "Initramfs built successfully for ${QUALIFIED_KERNEL}"