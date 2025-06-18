#!/usr/bin/env bash

# Soltros OS Setup Script
# Converted from justfile to bash script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

show_help() {
    cat << EOF
Soltros OS Setup Script

Usage: $0 [COMMAND]

INSTALL COMMANDS:
  install                 Install all Soltros components
  install-flatpaks        Install Flatpak applications from remote list
  install-dev-tools       Install development tools via Flatpak
  install-gaming          Install gaming tools via Flatpak
  install-multimedia      Install multimedia tools

SETUP COMMANDS:
  setup-git              Configure Git with user credentials and SSH signing
  setup-cli              Setup shell configurations and tools
  setup-distrobox        Setup distrobox containers for development

CONFIGURE COMMANDS:
  enable-amdgpu-oc       Enable AMD GPU overclocking support
  toggle-session         Information about toggling between X11 and Wayland

OTHER COMMANDS:
  help                   Show this help message
  list                   List all available commands

If no command is provided, the help will be shown.
EOF
}

list_commands() {
    echo "Available commands:"
    echo "  install install-flatpaks install-dev-tools install-gaming install-multimedia"
    echo "  setup-git setup-cli setup-distrobox"
    echo "  enable-amdgpu-oc toggle-session"
    echo "  help list"
}

# Install Functions
soltros_install() {
    print_header "Installing all Soltros components"
    soltros_install_flatpaks
}

soltros_install_flatpaks() {
    print_header "Installing Flatpak applications from remote list"
    
    if ! command -v flatpak &> /dev/null; then
        print_error "Flatpak is not installed"
        exit 1
    fi
    
    echo "Downloading flatpak list and installing..."
    if xargs -a <(curl --retry 3 -sL https://raw.githubusercontent.com/soltros/Soltros-OS/main/repo_files/flatpaks) flatpak --system -y install --reinstall; then
        print_success "Flatpaks installation complete"
    else
        print_error "Failed to install flatpaks"
        exit 1
    fi
}

install_dev_tools() {
    print_header "Installing development tools"
    
    echo "Installing development tools via Flatpak..."
    if flatpak install -y flathub \
        com.visualstudio.code \
        org.freedesktop.Sdk \
        org.freedesktop.Platform \
        com.github.Eloston.UngoogledChromium \
        io.podman_desktop.PodmanDesktop \
        com.jetbrains.IntelliJ-IDEA-Community; then
        print_success "Development tools installed!"
    else
        print_error "Failed to install development tools"
        exit 1
    fi
}

install_gaming() {
    print_header "Installing gaming applications"
    
    echo "Installing gaming applications via Flatpak..."
    if flatpak install -y flathub \
        com.valvesoftware.Steam \
        com.heroicgameslauncher.hgl \
        org.bottles.Bottles \
        net.lutris.Lutris \
        com.obsproject.Studio \
        com.discordapp.Discord; then
        print_success "Gaming setup complete!"
    else
        print_error "Failed to install gaming applications"
        exit 1
    fi
}

install_multimedia() {
    print_header "Installing multimedia applications"
    
    echo "Installing multimedia applications via Flatpak..."
    if flatpak install -y flathub \
        org.audacityteam.Audacity \
        org.blender.Blender \
        org.gimp.GIMP \
        org.inkscape.Inkscape \
        org.kde.kdenlive \
        com.spotify.Client \
        org.videolan.VLC; then
        print_success "Multimedia tools installed!"
    else
        print_error "Failed to install multimedia tools"
        exit 1
    fi
}

# Setup Functions
soltros_setup_git() {
    print_header "Setting up Git configuration"
    
    echo "Setting up Git config..."
    read -p "Enter your Git username: " git_username
    read -p "Enter your Git email: " git_email

    git config --global color.ui true
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"

    if [ ! -f "${HOME}/.ssh/id_ed25519.pub" ]; then
        echo "SSH key not found. Generating..."
        ssh-keygen -t ed25519 -C "$git_email"
    fi

    echo "Your SSH public key:"
    cat "${HOME}/.ssh/id_ed25519.pub"

    git config --global gpg.format ssh
    git config --global user.signingkey "key::$(cat ${HOME}/.ssh/id_ed25519.pub)"
    git config --global commit.gpgSign true

    echo "Setting up Git aliases..."
    git config --global alias.add-nowhitespace '!git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -'
    git config --global alias.graph 'log --decorate --oneline --graph'
    git config --global alias.ll 'log --oneline'
    git config --global alias.prune-all '!git remote | xargs -n 1 git remote prune'
    git config --global alias.pullr 'pull --rebase'
    git config --global alias.pushall '!git remote | xargs -L1 git push --all'
    git config --global alias.pushfwl 'push --force-with-lease'

    git config --global feature.manyFiles true
    git config --global init.defaultBranch main
    git config --global core.excludesFile '~/.gitignore'
    
    print_success "Git setup complete"
}

soltros_setup_cli() {
    print_header "Setting up shell configurations and tools"
    
    # Create necessary directories
    mkdir -p "${HOME}/.bashrc.d" \
             "${HOME}/.zshrc.d" \
             "${HOME}/.config/fish/completions" \
             "${HOME}/.config/fish/conf.d" \
             "${HOME}/.config/fish/functions"

    echo "Setting up shell aliases..."
    echo '[ -f "/usr/share/soltros/bling/aliases.sh" ]; bass source /usr/share/soltros/bling/aliases.sh' | tee "${HOME}/.config/fish/conf.d/soltros-aliases.fish" >/dev/null
    echo '[ -f "/usr/share/soltros/bling/aliases.sh" ] && . "/usr/share/soltros/bling/aliases.sh"' | tee "${HOME}/.bashrc.d/soltros-aliases.bashrc" "${HOME}/.zshrc.d/soltros-aliases.zshrc" >/dev/null

    echo "Setting up shell defaults..."
    echo '[ -f "/usr/share/soltros/bling/defaults.fish" ]; source /usr/share/soltros/bling/defaults.fish' | tee "${HOME}/.config/fish/conf.d/soltros-defaults.fish" >/dev/null
    echo '[ -f "/usr/share/soltros/bling/defaults.sh" ] && . "/usr/share/soltros/bling/defaults.sh"' | tee "${HOME}/.bashrc.d/soltros-defaults.bashrc" "${HOME}/.zshrc.d/soltros-defaults.zshrc" >/dev/null

    echo "Downloading Fish plugins..."
    wget -q https://github.com/edc/bass/raw/7296c6e70cf577a08a2a7d0e919e428509640e0f/functions/__bass.py -O "${HOME}/.config/fish/functions/__bass.py"
    wget -q https://github.com/edc/bass/raw/7296c6e70cf577a08a2a7d0e919e428509640e0f/functions/bass.fish -O "${HOME}/.config/fish/functions/bass.fish"
    wget -q https://github.com/garabik/grc/raw/4e1e9d7fdc9965c129f27d89c493d07f4b8307bb/grc.fish -O "${HOME}/.config/fish/conf.d/grc.fish"

    echo "Setting up Fish tools..."
    echo '[ -f "${HOME}/.cargo/env.fish" ] && source "${HOME}/.cargo/env.fish"' | tee "${HOME}/.config/fish/conf.d/cargo-env.fish" >/dev/null

    ATUIN_INIT_FLAGS=${ATUIN_INIT_FLAGS:-"--disable-up-arrow"}
    for tool in starship atuin zoxide thefuck direnv; do
        if command -v "$tool" >/dev/null; then
            case "$tool" in
            atuin)
                $tool init fish $ATUIN_INIT_FLAGS > "${HOME}/.config/fish/conf.d/${tool}.fish"
                ;;
            starship | zoxide)
                $tool init fish > "${HOME}/.config/fish/conf.d/${tool}.fish"
                ;;
            thefuck)
                $tool --alias > "${HOME}/.config/fish/functions/${tool}.fish"
                ;;
            direnv)
                $tool hook fish > "${HOME}/.config/fish/conf.d/${tool}.fish"
                ;;
            esac
        fi
    done

    echo "Configuring rc file sourcing..."
    for shell in bash zsh; do
        rc_file="${HOME}/.${shell}rc"
        rc_dir=".${shell}rc.d"

        # Check if the snippet already exists
        if [ -f "$rc_file" ] && grep -q "${rc_dir}/\*" "$rc_file"; then
            echo "RC sourcing already configured for $shell"
        else
            # Add the snippet using printf to avoid parsing issues
            printf '\n%s\n' "# User-specific aliases and functions" >> "$rc_file"
            printf '%s\n' "if [ -d ~/${rc_dir} ]; then" >> "$rc_file"
            printf '%s\n' "  for rc in ~/${rc_dir}/*; do" >> "$rc_file"
            printf '%s\n' '    if [ -f "$rc" ]; then' >> "$rc_file"
            printf '%s\n' '      . "$rc"' >> "$rc_file"
            printf '%s\n' "    fi" >> "$rc_file"
            printf '%s\n' "  done" >> "$rc_file"
            printf '%s\n' "fi" >> "$rc_file"
            printf '%s\n' "unset rc" >> "$rc_file"
            echo "Added RC sourcing for $shell"
        fi
    done

    print_success "Terminal setup complete"
}

setup_distrobox() {
    print_header "Setting up distrobox containers for development"
    
    if ! command -v distrobox &> /dev/null; then
        print_error "Distrobox is not installed"
        exit 1
    fi
    
    # Ubuntu container for general development
    if ! distrobox list | grep -q "ubuntu-dev"; then
        echo "Creating Ubuntu development container..."
        distrobox create --name ubuntu-dev --image ubuntu:latest
        distrobox enter ubuntu-dev -- sudo apt update && sudo apt install -y build-essential git curl wget
    else
        echo "Ubuntu development container already exists"
    fi
    
    # Arch container for AUR packages
    if ! distrobox list | grep -q "arch-dev"; then
        echo "Creating Arch development container..."
        distrobox create --name arch-dev --image archlinux:latest
        distrobox enter arch-dev -- sudo pacman -Syu --noconfirm base-devel git
    else
        echo "Arch development container already exists"
    fi
    
    print_success "Distrobox setup complete!"
}

# Configure Functions
soltros_enable_amdgpu_oc() {
    print_header "Enabling AMD GPU overclocking support"
    
    if ! command -v rpm-ostree &> /dev/null; then
        print_error "rpm-ostree is not available"
        exit 1
    fi
    
    if ! rpm-ostree kargs | grep -q "amdgpu.ppfeaturemask="; then
        sudo rpm-ostree kargs --append "amdgpu.ppfeaturemask=0xFFF7FFFF"
        print_success "Kernel argument set. Reboot required to take effect."
    else
        print_warning "Overclocking already enabled"
    fi
}

toggle_session() {
    print_header "Session Toggle Information"
    
    current_session=$(echo $XDG_SESSION_TYPE)
    echo "Current session: $current_session"
    
    if [ "$current_session" = "wayland" ]; then
        echo "To switch to X11:"
        echo "1. Log out of your current session"
        echo "2. On the login screen, click the gear icon"
        echo "3. Select the X11 session option"
        echo "4. Log back in"
    else
        echo "To switch to Wayland:"
        echo "1. Log out of your current session"
        echo "2. On the login screen, click the gear icon"
        echo "3. Select the Wayland session option"
        echo "4. Log back in"
    fi
}

# Main script logic
main() {
    case "${1:-help}" in
        "install")
            soltros_install
            ;;
        "install-flatpaks")
            soltros_install_flatpaks
            ;;
        "install-dev-tools")
            install_dev_tools
            ;;
        "install-gaming")
            install_gaming
            ;;
        "install-multimedia")
            install_multimedia
            ;;
        "setup-git")
            soltros_setup_git
            ;;
        "setup-cli")
            soltros_setup_cli
            ;;
        "setup-distrobox")
            setup_distrobox
            ;;
        "enable-amdgpu-oc")
            soltros_enable_amdgpu_oc
            ;;
        "toggle-session")
            toggle_session
            ;;
        "list")
            list_commands
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
