#!/bin/bash

# Enhanced Nix Package Manager
# A contextual, sub-command based script for managing Nix packages

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script name for usage
SCRIPT_NAME=$(basename "$0")

# Function to display usage
usage() {
    echo -e "${BLUE}Usage: $SCRIPT_NAME <command> [options]${NC}"
    echo ""
    echo "Commands:"
    echo "  install <package>    Install a package from nixpkgs"
    echo "  remove <package>     Remove an installed package (by name or index)"
    echo "  list                 List installed packages"
    echo "  search <query>       Search for packages in nixpkgs"
    echo "  upgrade              Upgrade all packages"
    echo "  help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $SCRIPT_NAME install firefox"
    echo "  $SCRIPT_NAME remove firefox"
    echo "  $SCRIPT_NAME search vim"
    echo "  $SCRIPT_NAME list"
}

# Function to check if nix is available
check_nix() {
    if ! command -v nix &> /dev/null; then
        echo -e "${RED}Error: Nix is not installed or not in PATH${NC}" >&2
        exit 1
    fi
}

# Function to update desktop environment shortcuts
update_desktop_shortcuts() {
    echo -e "${BLUE}Updating desktop shortcuts...${NC}"
    
    # Determinate Nix installer paths
    local nix_profile_path="$HOME/.nix-profile"
    local nix_var_path="/var/home/nix"
    
    # Update desktop database for Nix profile paths
    if command -v update-desktop-database &> /dev/null; then
        # Update for the current user's Nix profile
        if [[ -d "$nix_profile_path/share/applications" ]]; then
            update-desktop-database "$nix_profile_path/share/applications" 2>/dev/null || true
        fi
        
        # Also update standard user directories
        update-desktop-database ~/.local/share/applications/ 2>/dev/null || true
    fi
    
    # Update MIME database for Nix profile
    if command -v update-mime-database &> /dev/null; then
        if [[ -d "$nix_profile_path/share/mime" ]]; then
            update-mime-database "$nix_profile_path/share/mime" 2>/dev/null || true
        fi
        update-mime-database ~/.local/share/mime/ 2>/dev/null || true
    fi
    
    # Update icon cache for Nix profile icons
    if command -v gtk-update-icon-cache &> /dev/null; then
        if [[ -d "$nix_profile_path/share/icons/hicolor" ]]; then
            gtk-update-icon-cache -f -t "$nix_profile_path/share/icons/hicolor" 2>/dev/null || true
        fi
        # Standard icon paths
        gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor/ 2>/dev/null || true
    fi
    
    # KDE Plasma specific updates
    if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || [[ "$DESKTOP_SESSION" == *"plasma"* ]]; then
        # Force rebuild of KDE service cache to pick up new .desktop files
        if command -v kbuildsycoca5 &> /dev/null; then
            kbuildsycoca5 --noincremental 2>/dev/null || true
        elif command -v kbuildsycoca6 &> /dev/null; then
            kbuildsycoca6 --noincremental 2>/dev/null || true
        fi
        
        # Notify KDE about new applications
        if command -v qdbus &> /dev/null; then
            qdbus org.kde.KLauncher /KLauncher reparseConfiguration 2>/dev/null || true
        fi
    fi
    
    # GNOME specific updates
    if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
        # Update GNOME's application cache
        if command -v glib-compile-schemas &> /dev/null; then
            if [[ -d "$nix_profile_path/share/glib-2.0/schemas" ]]; then
                glib-compile-schemas "$nix_profile_path/share/glib-2.0/schemas" 2>/dev/null || true
            fi
        fi
    fi
    
    # Force XDG to rescan application directories
    if command -v xdg-desktop-menu &> /dev/null; then
        xdg-desktop-menu forceupdate 2>/dev/null || true
    fi
    
    # Refresh systemd user environment (for immutable OS integration)
    if command -v systemctl &> /dev/null; then
        systemctl --user daemon-reload 2>/dev/null || true
    fi
    
    # Send SIGHUP to update desktop environment
    if command -v pkill &> /dev/null; then
        # This can help refresh some desktop environments
        pkill -HUP -f "gnome-shell\|plasmashell\|xfce4-panel" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✓ Desktop shortcuts updated for Nix profile${NC}"
}

# Function to install a package
install_package() {
    local package="$1"
    
    if [[ -z "$package" ]]; then
        echo -e "${RED}Error: Package name is required${NC}" >&2
        echo "Usage: $SCRIPT_NAME install <package>"
        exit 1
    fi
    
    echo -e "${BLUE}Installing package: $package${NC}"
    
    if NIXPKGS_ALLOW_UNFREE=1 nix profile add "nixpkgs#$package"; then
        echo -e "${GREEN}✓ Successfully installed: $package${NC}"
        update_desktop_shortcuts
    else
        echo -e "${RED}✗ Failed to install: $package${NC}" >&2
        echo "Use '$SCRIPT_NAME search $package' to find available packages"
        exit 1
    fi
}

# Function to remove a package
remove_package() {
    local package="$1"
    
    if [[ -z "$package" ]]; then
        echo -e "${RED}Error: Package name or index is required${NC}" >&2
        echo "Usage: $SCRIPT_NAME remove <package_name_or_index>"
        exit 1
    fi
    
    echo -e "${BLUE}Removing package: $package${NC}"
    
    if nix profile remove "$package"; then
        echo -e "${GREEN}✓ Successfully removed: $package${NC}"
        update_desktop_shortcuts
    else
        echo -e "${RED}✗ Failed to remove: $package${NC}" >&2
        echo "Use '$SCRIPT_NAME list' to see installed packages and their indices"
        exit 1
    fi
}

# Function to list installed packages
list_packages() {
    echo -e "${BLUE}Installed packages:${NC}"
    nix profile list
}

# Function to search for packages
search_packages() {
    local query="$1"
    
    if [[ -z "$query" ]]; then
        echo -e "${RED}Error: Search query is required${NC}" >&2
        echo "Usage: $SCRIPT_NAME search <query>"
        exit 1
    fi
    
    echo -e "${BLUE}Searching for packages matching: $query${NC}"
    NIXPKGS_ALLOW_UNFREE=1 nix search nixpkgs "$query"
}

# Function to upgrade all packages
upgrade_packages() {
    echo -e "${BLUE}Upgrading all packages...${NC}"
    if nix profile upgrade; then
        echo -e "${GREEN}✓ All packages upgraded successfully${NC}"
    else
        echo -e "${RED}✗ Failed to upgrade packages${NC}" >&2
        exit 1
    fi
}

# Main function to handle commands
main() {
    # Check if nix is available
    check_nix
    
    # Check if at least one argument is provided
    if [[ $# -eq 0 ]]; then
        usage
        exit 1
    fi
    
    local command="$1"
    
    case "$command" in
        install)
            shift
            install_package "$1"
            ;;
        remove)
            shift
            remove_package "$1"
            ;;
        list)
            list_packages
            ;;
        search)
            shift
            search_packages "$1"
            ;;
        upgrade)
            upgrade_packages
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown command '$command'${NC}" >&2
            echo ""
            usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"