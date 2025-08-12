#!/usr/bin/bash
set ${SET_X:+-x} -eou pipefail
# Define log function first (before any usage)
log() {
echo "== $* =="
}
trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

# Script to remove Just and Bazaar tools from Aurora-DX and reinstall Discover
# Place this in /ctx and make it executable

log "Aurora-DX Cleanup Script"
log "Removing Just and Bazaar, reinstalling Discover..."

# Remove Just tool files
log "Removing Just..."
if [ -f "/usr/bin/just" ]; then
    sudo rm -f /usr/bin/just
    echo "✓ Removed /usr/bin/just"
fi

if [ -f "/usr/share/man/man1/just.1.gz" ]; then
    sudo rm -f /usr/share/man/man1/just.1.gz
    echo "✓ Removed just man page"
fi

# Remove Bazaar files
log "Removing Bazaar..."
if [ -f "/usr/bin/bazaar" ]; then
    sudo rm -f /usr/bin/bazaar
    echo "✓ Removed /usr/bin/bazaar"
fi

if [ -f "/usr/share/applications/io.github.kolunmi.Bazaar.desktop" ]; then
    sudo rm -f /usr/share/applications/io.github.kolunmi.Bazaar.desktop
    echo "✓ Removed Bazaar desktop file"
fi

# Remove ublue-os directory
log "Removing ublue-os directory..."
if [ -d "/usr/share/ublue-os" ]; then
    sudo rm -rf /usr/share/ublue-os
    echo "✓ Removed /usr/share/ublue-os directory"
fi

# Update desktop database after removing .desktop file
sudo update-desktop-database /usr/share/applications/ 2>/dev/null || true

# Check if Discover is installed, if not install it
log "Checking Discover installation..."
if ! command -v plasma-discover &> /dev/null; then
    log "Installing Discover with all components..."
    
    # Define all Discover packages
    DISCOVER_PACKAGES=(
        "plasma-discover"
        "plasma-discover-flatpak"
        "plasma-discover-kns"
        "plasma-discover-libs"
        "plasma-discover-notifier"
        "plasma-discover-offline-updates"
        "plasma-discover-packagekit"
        "plasma-discover-rpm-ostree"
    )
    
    # Try different package managers that might be available
    if command -v rpm-ostree &> /dev/null; then
        # Aurora-DX uses rpm-ostree
        log "Installing via rpm-ostree..."
        sudo rpm-ostree install "${DISCOVER_PACKAGES[@]}"
        echo "✓ Discover and all components installed via rpm-ostree (reboot required)"
        echo "⚠️  You'll need to reboot to complete the installation"
    elif command -v dnf &> /dev/null; then
        log "Installing via dnf..."
        sudo dnf install -y "${DISCOVER_PACKAGES[@]}"
        echo "✓ Discover and all components installed via dnf"
    else
        echo "❌ Could not find a suitable package manager to install Discover"
        exit 1
    fi
else
    echo "✓ Discover is already installed"
    log "Checking for missing Discover components..."
    
    # Check if individual components are installed and install missing ones
    MISSING_PACKAGES=()
    DISCOVER_PACKAGES=(
        "plasma-discover-flatpak"
        "plasma-discover-kns"
        "plasma-discover-libs"
        "plasma-discover-notifier"
        "plasma-discover-offline-updates"
        "plasma-discover-packagekit"
        "plasma-discover-rpm-ostree"
    )
    
    for package in "${DISCOVER_PACKAGES[@]}"; do
        if command -v rpm &> /dev/null; then
            if ! rpm -q "$package" &> /dev/null; then
                MISSING_PACKAGES+=("$package")
            fi
        elif command -v dpkg &> /dev/null; then
            if ! dpkg -l "$package" &> /dev/null 2>&1; then
                MISSING_PACKAGES+=("$package")
            fi
        fi
    done
    
    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        echo "Installing missing components: ${MISSING_PACKAGES[*]}"
        if command -v rpm-ostree &> /dev/null; then
            sudo rpm-ostree install "${MISSING_PACKAGES[@]}"
            echo "✓ Missing components installed via rpm-ostree (reboot required)"
            echo "⚠️  You'll need to reboot to complete the installation"
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y "${MISSING_PACKAGES[@]}"
            echo "✓ Missing components installed via dnf"
        fi
    else
        echo "✓ All Discover components are already installed"
    fi
fi

# Clean up any cached files or configs related to the removed tools
log "Cleaning up..."

# Remove any user configs for these tools (optional)
if [ -d "$HOME/.config/bazaar" ]; then
    rm -rf "$HOME/.config/bazaar"
    echo "✓ Removed user Bazaar config"
fi

# Clear any cached data
if command -v updatedb &> /dev/null; then
    sudo updatedb 2>/dev/null || true
fi

log "Cleanup Complete"
echo "✓ Just tool removed"
echo "✓ Bazaar removed"
echo "✓ ublue-os directory removed"
echo "✓ Discover installation verified"
echo ""
echo "If you installed Discover via rpm-ostree, please reboot to complete the process."
echo "Otherwise, you should be able to launch Discover from your applications menu."