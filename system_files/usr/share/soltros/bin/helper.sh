#!/usr/bin/env bash
# SoltrOS Setup Script
# Converted from justfile to standalone bash script

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

show_help() {
    cat << 'EOF'
SoltrOS Setup Script

Usage: helper [COMMAND]

INSTALL COMMANDS:
  install                 Install all SoltrOS components
  install-flatpaks        Install Flatpak applications from remote list
  install-dev-tools       Install development tools via Flatpak
  install-gaming          Install gaming tools via Flatpak
  install-multimedia      Install multimedia tools via Flatpak
  install-homebrew        Install the Homebrew package manager
  install-nix             Install the Nix package manager
  setup-nixmanager        Add the nixmanager.sh script to ~/scripts for easy Nix use
  add-helper              This adds the helper.sh alias to Bash to make it easier to access
  download-appimages      Download Feishin and Ryubing to the ~/AppImages folder
  install-oh-my-zsh       Download and install the Oh My Zsh plugins/tools
  change-to-zsh           Swap shell to Zsh
  download-zsh-configs    Download Derrik's Zshrc config
  apply-soltros-look      Apply the SoltrOS theme to Plasma

SETUP COMMANDS:
  setup-git              Configure Git with user credentials and SSH signing
  setup-cli              Setup shell configurations and tools
  setup-distrobox        Setup distrobox containers for development

CONFIGURE COMMANDS:
  enable-amdgpu-oc       Enable AMD GPU overclocking support
  toggle-session         Toggle between X11 and Wayland sessions

OTHER COMMANDS:
  update                 Update the system (rpm-ostree, flatpaks, etc.)
  clean                  Clean up the system
  distrobox              Manage distrobox containers
  toolbox                Manage toolbox containers

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
    echo "  update clean distrobox toolbox"
    echo "  help list"
}

# ───────────────────────────────────────────────
# INSTALL FUNCTIONS
# ───────────────────────────────────────────────

soltros_install() {
    print_header "Installing all SoltrOS components"
    soltros_install_flatpaks
}

soltros_install_flatpaks() {
    print_header "Installing Flatpak applications from remote list"
    
    print_info "Setting up Flathub repository..."
    if ! flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
        print_error "Failed to add Flathub repository"
        exit 1
    fi
    
    print_info "Downloading flatpak list and installing..."
    if xargs -a <(curl --retry 3 -sL https://raw.githubusercontent.com/soltros/Soltros-OS/main/repo_files/flatpaks) flatpak --system -y install --reinstall; then
        print_success "Flatpaks installation complete"
    else
        print_error "Failed to install flatpaks"
        exit 1
    fi
}

install_dev_tools() {
    print_header "Installing development tools via Flatpak"
    
    print_info "Installing development tools..."
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

install_homebrew() {
    print_header "Setting up Homebrew"
    if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        # Add Homebrew to PATH (the installer usually tells you the correct path)
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.bashrc
        print_success "Brew package manager installed!"
        echo "Please restart your terminal or run 'source ~/.bashrc' to use brew"
    else
        print_error "Failed to install the Brew package manager"
        exit 1
    fi
}

install_nix() {
    print_header "Setting up Nix via Determinite Nix installer."
    if /bin/bash /nix/determinate-nix-installer.sh install
        mkdir -p ~/.config/nixpkgs-soltros/
        wget https://raw.githubusercontent.com/soltros/random-stuff/refs/heads/main/configs/flake.nix -O ~/.config/nixpkgs-soltros/flake.nix; then
        print_success "Successfully installed and enabled the Nix package manager on SoltrOS."
    else
        print_error "Failed to install and enable the Nix package manager on SoltrOS."
        exit 1
    fi
}

setup_nixmanager() {
    print_header "Setting up the nixmanager.sh script."
    if mkdir -p ~/scripts/
    cp /usr/share/soltros/bin/nixmanager.sh ~/scripts/
    chmod +x ~/scripts/nixmanager.sh; then
        print_success "nixmanager.sh installed! Please run sh ~/scripts/nixmanager.sh, or nixmanager in the Zsh shell!"
    else
        print_error "Failed to setup nixmanager.sh"
        exit 1
    fi
}

add_helper() {
    local bashrc="$HOME/.bashrc"
    local alias_cmd='alias helper="sh /usr/share/soltros/bin/helper.sh"'

    # Check if the alias already exists
    if grep -Fxq "$alias_cmd" "$bashrc"; then
        echo "✓ Alias already exists in $bashrc"
    else
        echo "$alias_cmd" >> "$bashrc"
        echo "✓ Alias added to $bashrc"
    fi
}

apply_soltros_look() {
    print_header "Applying the official SoltrOS look."
    
    local remote_url="https://raw.githubusercontent.com/soltros/Soltros-OS/refs/heads/main/resources/kde-plasma-settings.tar.gz"
    local temp_archive="/tmp/kde-plasma-settings.tar.gz"
    
    print_info "Downloading KDE settings from SoltrOS repository..."
    if ! curl --retry 3 -sL "$remote_url" -o "$temp_archive"; then
        print_error "Failed to download settings archive"
        return 1
    fi
    
    print_warning "This will overwrite your current KDE settings!"
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Restore cancelled"
        rm -f "$temp_archive"
        return 0
    fi
    
    print_info "Stopping Plasma shell..."
    killall plasmashell 2>/dev/null || true
    
    print_info "Extracting KDE settings..."
    if tar -xzf "$temp_archive" -C ~ --overwrite; then
        print_success "Settings extracted successfully"
        print_info "Restored files:"
        print_info "  • Icon theme (kdeglobals, kdedefaults/kdeglobals)"
        print_info "  • Panel & kickoff configuration (plasma-org.kde.plasma.desktop-appletsrc)"
        print_info "  • Plasma shell settings (plasmashellrc, plasmarc)"
        print_info "  • Window manager settings (kwinrc)"
        print_info "  • Global shortcuts (kglobalshortcutsrc)"
    else
        print_error "Failed to extract settings"
        rm -f "$temp_archive"
        return 1
    fi

    print_info "Setting Papirus icon theme explicitly..."
    kwriteconfig5 --file kdeglobals --group Icons --key Theme Papirus

    print_info "Restarting Plasma shell..."
    nohup plasmashell &>/dev/null &
    
    # Cleanup
    rm -f "$temp_archive"
    
    print_success "SoltrOS look applied!"
    print_info "Some changes may require logging out and back in to take full effect"
}


install_oh_my_zsh() {
    print_header "Setting up Oh My Zsh!"
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; then
        print_success "Oh My Zsh! installed."
    else
        print_error "Failed to install Oh My Zsh"
        exit 1
    fi
} 

change_to_zsh() {
    print_header "Changing shell to Zsh"
    if chsh -s /usr/sbin/zsh; then
        print_success "Changed from Bash to Zsh"
    else
        print_error "Failed to change from Bash to Zsh"
        exit 1
    fi
}

download_zsh_configs() {
    if wget https://raw.githubusercontent.com/soltros/random-stuff/refs/heads/main/zsh/zshrc -O ~/.zshrc
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions; then
        print_success "Successfully downloaded Zshrc."
    else
        print_error "Failed to download Zshrc"
        exit 1
    fi
}

install_gaming() {
    print_header "Installing gaming applications via Flatpak"
    
    print_info "Installing gaming applications..."
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

download_appimages() {
    print_header "Downloading AppImages"

    print_info "Downloading AppImages..."
    if mkdir -p ~/AppImages/; then
        wget https://github.com/jeffvli/feishin/releases/download/v0.17.0/Feishin-0.17.0-linux-x86_64.AppImage -O ~/AppImages/Feishin-0.17.0-linux-x86_64.AppImage
        wget https://git.ryujinx.app/api/v4/projects/1/packages/generic/Ryubing/1.3.2/ryujinx-1.3.2-x64.AppImage -O ~/AppImages/ryujinx-1.3.2-x64.AppImage
        print_success AppImage files downloaded to ~/AppImages/
    else
        print_error "Failed to download AppImage files"
        exit 1
    fi
}

install_multimedia() {
    print_header "Installing multimedia applications via Flatpak"
    
    print_info "Installing multimedia applications..."
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

# ───────────────────────────────────────────────
# SETUP FUNCTIONS
# ───────────────────────────────────────────────

soltros_setup_git() {
    print_header "Setting up Git configuration"
    
    print_info "Setting up Git config..."
    read -p "Enter your Git username: " git_username
    read -p "Enter your Git email: " git_email

    git config --global color.ui true
    git config --global user.name "$git_username"
    git config --global user.email "$git_email"

    if [ ! -f "${HOME}/.ssh/id_ed25519.pub" ]; then
        print_info "SSH key not found. Generating..."
        ssh-keygen -t ed25519 -C "$git_email"
    fi

    print_info "Your SSH public key:"
    cat "${HOME}/.ssh/id_ed25519.pub"

    git config --global gpg.format ssh
    git config --global user.signingkey "key::$(cat ${HOME}/.ssh/id_ed25519.pub)"
    git config --global commit.gpgSign true

    print_info "Setting up Git aliases..."
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

    print_info "Setting up shell aliases..."
    echo '[ -f "/usr/share/soltros/bling/aliases.sh" ]; bass source /usr/share/soltros/bling/aliases.sh' | tee "${HOME}/.config/fish/conf.d/soltros-aliases.fish" >/dev/null
    echo '[ -f "/usr/share/soltros/bling/aliases.sh" ] && . "/usr/share/soltros/bling/aliases.sh"' | tee "${HOME}/.bashrc.d/soltros-aliases.bashrc" "${HOME}/.zshrc.d/soltros-aliases.zshrc" >/dev/null

    print_info "Setting up shell defaults..."
    echo '[ -f "/usr/share/soltros/bling/defaults.fish" ]; source /usr/share/soltros/bling/defaults.fish' | tee "${HOME}/.config/fish/conf.d/soltros-defaults.fish" >/dev/null
    echo '[ -f "/usr/share/soltros/bling/defaults.sh" ] && . "/usr/share/soltros/bling/defaults.sh"' | tee "${HOME}/.bashrc.d/soltros-defaults.bashrc" "${HOME}/.zshrc.d/soltros-defaults.zshrc" >/dev/null

    print_info "Downloading Fish plugins..."
    wget -q https://github.com/edc/bass/raw/7296c6e70cf577a08a2a7d0e919e428509640e0f/functions/__bass.py -O "${HOME}/.config/fish/functions/__bass.py"
    wget -q https://github.com/edc/bass/raw/7296c6e70cf577a08a2a7d0e919e428509640e0f/functions/bass.fish -O "${HOME}/.config/fish/functions/bass.fish"
    wget -q https://github.com/garabik/grc/raw/4e1e9d7fdc9965c129f27d89c493d07f4b8307bb/grc.fish -O "${HOME}/.config/fish/conf.d/grc.fish"

    print_info "Setting up Fish tools..."
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

    print_info "Configuring rc file sourcing..."
    for shell in bash zsh; do
        rc_file="${HOME}/.${shell}rc"
        rc_dir=".${shell}rc.d"

        # Check if the snippet already exists
        if [ -f "$rc_file" ] && grep -q "${rc_dir}/\*" "$rc_file"; then
            print_info "RC sourcing already configured for $shell"
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
            print_info "Added RC sourcing for $shell"
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
        print_info "Creating Ubuntu development container..."
        distrobox create --name ubuntu-dev --image ubuntu:latest
        distrobox enter ubuntu-dev -- sudo apt update && sudo apt install -y build-essential git curl wget
    else
        print_info "Ubuntu development container already exists"
    fi
    
    # Arch container for AUR packages
    if ! distrobox list | grep -q "arch-dev"; then
        print_info "Creating Arch development container..."
        distrobox create --name arch-dev --image archlinux:latest
        distrobox enter arch-dev -- sudo pacman -Syu --noconfirm base-devel git
    else
        print_info "Arch development container already exists"
    fi
    
    print_success "Distrobox setup complete!"
}

# ───────────────────────────────────────────────
# CONFIGURE FUNCTIONS
# ───────────────────────────────────────────────

soltros_enable_amdgpu_oc() {
    print_header "Enabling AMD GPU overclocking support"
    
    if ! command -v rpm-ostree &> /dev/null; then
        print_error "rpm-ostree is not available"
        exit 1
    fi
    
    print_info "Enabling AMD GPU overclocking..."
    
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
    print_info "Current session: $current_session"
    
    if [ "$current_session" = "wayland" ]; then
        print_info "To switch to X11:"
        echo "1. Log out of your current session"
        echo "2. On the login screen, click the gear icon"
        echo "3. Select the X11 session option"
        echo "4. Log back in"
    else
        print_info "To switch to Wayland:"
        echo "1. Log out of your current session"
        echo "2. On the login screen, click the gear icon"
        echo "3. Select the Wayland session option"
        echo "4. Log back in"
    fi
}

# ───────────────────────────────────────────────
# UNIVERSAL BLUE FUNCTIONS
# ───────────────────────────────────────────────

ublue_update() {
    print_header "Updating the system"
    
    print_info "Updating rpm-ostree..."
    sudo rpm-ostree upgrade || true
    
    print_info "Updating Flatpaks..."
    flatpak update -y || true
    
    if command -v distrobox &> /dev/null; then
        print_info "Updating distrobox containers..."
        distrobox upgrade --all || true
    fi
    
    if command -v toolbox &> /dev/null; then
        print_info "Updating toolbox containers..."
        for container in $(toolbox list -c | tail -n +2 | awk '{print $2}'); do
            toolbox run -c "$container" sudo dnf update -y || true
        done
    fi
    
    print_success "System update complete"
}

ublue_clean() {
    print_header "Cleaning up the system"
    
    print_info "Cleaning rpm-ostree..."
    sudo rpm-ostree cleanup -p || true
    
    print_info "Cleaning Flatpak cache..."
    flatpak uninstall --unused -y || true
    
    print_info "Cleaning system cache..."
    sudo journalctl --vacuum-time=7d || true
    
    print_success "System cleanup complete"
}

ublue_distrobox() {
    print_header "Managing distrobox containers"
    
    if ! command -v distrobox &> /dev/null; then
        print_error "Distrobox is not installed"
        exit 1
    fi
    
    print_info "Available distrobox containers:"
    distrobox list
}

ublue_toolbox() {
    print_header "Managing toolbox containers"
    
    if ! command -v toolbox &> /dev/null; then
        print_error "Toolbox is not installed"
        exit 1
    fi
    
    print_info "Available toolbox containers:"
    toolbox list
}

# ───────────────────────────────────────────────
# MAIN SCRIPT LOGIC
# ───────────────────────────────────────────────

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
        "install-homebrew")
            install_homebrew
            ;;
        "install-nix")
            install_nix
            ;;
        "setup-nixmanager")
            setup_nixmanager
            ;;
        "apply-soltros-look")
            apply_soltros_look
            ;;
        "add-helper")
            add_helper
            ;;
        "install-oh-my-zsh")
            install_oh_my_zsh
            ;;
        "change-to-zsh")
            change_to_zsh
            ;;
        "download-zsh-configs")
            download_zsh_configs
            ;;
        "download-appimages")
            download_appimages
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
        "update")
            ublue_update
            ;;
        "clean")
            ublue_clean
            ;;
        "distrobox")
            ublue_distrobox
            ;;
        "toolbox")
            ublue_toolbox
            ;;
        "list")
            list_commands
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            echo "Unknown command: $1"
            echo "Run 'helper' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"