# Soltros OS Setup Justfile

# Imports
import "/usr/share/ublue-os/just/00-default.just"
import "/usr/share/ublue-os/just/10-update.just"
import "/usr/share/ublue-os/just/15-luks.just"
import "/usr/share/ublue-os/just/20-clean.just"
import "/usr/share/ublue-os/just/30-distrobox.just"
import "/usr/share/ublue-os/just/31-toolbox.just"
import "/usr/share/ublue-os/just/40-nvidia.just"
import "/usr/share/ublue-os/just/50-akmods.just"
import? "/usr/share/ublue-os/just/60-custom.just"

default:
    @just --list

# ───────────────────────────────────────────────
# INSTALL GROUP
# ───────────────────────────────────────────────

# Install all Soltros components
[group('Install')]
soltros-install: soltros-install-flatpaks

# Install Flatpak applications from remote list
[group('Install')]
soltros-install-flatpaks:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Installing Flatpaks..."
    xargs -a <(curl --retry 3 -sL https://raw.githubusercontent.com/soltros/Soltros-OS/main/repo_files/flatpaks) flatpak --system -y install
    echo "Flatpaks installation complete."

# Install development tools via Flatpak
[group('Install')]
install-dev-tools:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Installing development tools..."
    flatpak install -y flathub \
        com.visualstudio.code \
        org.freedesktop.Sdk \
        org.freedesktop.Platform \
        com.github.Eloston.UngoogledChromium \
        io.podman_desktop.PodmanDesktop \
        com.jetbrains.IntelliJ-IDEA-Community
    echo "Development tools installed!"

# Install gaming tools via Flatpak
[group('Install')]
install-gaming:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Installing gaming applications..."
    flatpak install -y flathub \
        com.valvesoftware.Steam \
        com.heroicgameslauncher.hgl \
        org.bottles.Bottles \
        net.lutris.Lutris \
        com.obsproject.Studio \
        com.discordapp.Discord
    echo "Gaming setup complete!"

# Install multimedia tools
[group('Install')]
install-multimedia:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Installing multimedia applications..."
    flatpak install -y flathub \
        org.audacityteam.Audacity \
        org.blender.Blender \
        org.gimp.GIMP \
        org.inkscape.Inkscape \
        org.kde.kdenlive \
        com.spotify.Client \
        org.videolan.VLC
    echo "Multimedia tools installed!"

# ───────────────────────────────────────────────
# SETUP GROUP
# ───────────────────────────────────────────────

# Configure Git with user credentials and SSH signing
[group('Setup')]
soltros-setup-git:
    #!/usr/bin/env bash
    set -euo pipefail

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
    cat ${HOME}/.ssh/id_ed25519.pub

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

# Setup shell configurations and tools
[group('Setup')]
soltros-setup-cli:
    #!/usr/bin/env bash
    set -euo pipefail

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
        command -v "$tool" >/dev/null && {
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
        }
    done

    echo "Configuring rc file sourcing..."
    for shell in bash zsh; do
        rc_file="${HOME}/.${shell}rc"
        rc_dir=".${shell}rc.d"

        # Check if the snippet already exists
        if [ -f "$rc_file" ] && grep -q "${rc_dir}/\*" "$rc_file"; then
            echo "RC sourcing already configured for $shell"
        else
            # Add the snippet
            cat >> "$rc_file" << SNIPPET

# User-specific aliases and functions
if [ -d ~/${rc_dir} ]; then
  for rc in ~/${rc_dir}/*; do
    if [ -f "\$rc" ]; then
      . "\$rc"
    fi
  done
fi
unset rc
SNIPPET
            echo "Added RC sourcing for $shell"
        fi
    done

    echo "Terminal setup complete."

# Setup distrobox containers for development
[group('Setup')]
setup-distrobox:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Setting up distrobox containers..."
    
    # Ubuntu container for general development
    if ! distrobox list | grep -q "ubuntu-dev"; then
        echo "Creating Ubuntu development container..."
        distrobox create --name ubuntu-dev --image ubuntu:latest
        distrobox enter ubuntu-dev -- sudo apt update && sudo apt install -y build-essential git curl wget
    fi
    
    # Arch container for AUR packages
    if ! distrobox list | grep -q "arch-dev"; then
        echo "Creating Arch development container..."
        distrobox create --name arch-dev --image archlinux:latest
        distrobox enter arch-dev -- sudo pacman -Syu --noconfirm base-devel git
    fi
    
    echo "Distrobox setup complete!"

# ───────────────────────────────────────────────
# CONFIGURE GROUP
# ───────────────────────────────────────────────

# Enable AMD GPU overclocking support
[group('Configure')]
soltros-enable-amdgpu-oc:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Enabling AMD GPU overclocking..."

    if ! rpm-ostree kargs | grep -q "amdgpu.ppfeaturemask="; then
        sudo rpm-ostree kargs --append "amdgpu.ppfeaturemask=0xFFF7FFFF"
        echo "Kernel argument set."
    else
        echo "Overclocking already enabled."
    fi

# Toggle between X11 and Wayland sessions
[group('Configure')]
toggle-session:
    #!/usr/bin/env bash
    set -euo pipefail
    
    current_session=$(echo $XDG_SESSION_TYPE)
    echo "Current session: $current_session"
    
    if [ "$current_session" = "wayland" ]; then
        echo "Switching to X11 for next login..."
        echo "Log out and select X11 session from login screen"
    else
        echo "Switching to Wayland for next login..."
        echo "Log out and select Wayland session from login screen"
    fi

# Configure automatic updates
[group('Configure')]
configure-auto-updates:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Configuring automatic system updates..."
    sudo systemctl enable rpm-ostreed-automatic.timer
    sudo systemctl start rpm-ostreed-automatic.timer
    
    # Configure flatpak auto-updates
    echo "Configuring Flatpak auto-updates..."
    systemctl --user enable flatpak-system-update.timer
    systemctl --user start flatpak-system-update.timer
    
    echo "Automatic updates configured!"

# ───────────────────────────────────────────────
# SYSTEM GROUP
# ───────────────────────────────────────────────

# Update system, flatpaks, and distroboxes
[group('System')]
update:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "── System update ──────────────────────────────────────────"
    sudo rpm-ostree upgrade
    
    echo "── Flatpak updates ────────────────────────────────────────"
    flatpak update -y
    
    echo "── Distrobox updates ──────────────────────────────────────"
    if command -v distrobox >/dev/null; then
        distrobox upgrade --all
    fi
    
    echo "── Update complete! ───────────────────────────────────────"

# Clean up system artifacts
[group('System')]
cleanup:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Cleaning up system..."
    
    # Clean RPM-OSTree
    sudo rpm-ostree cleanup -m
    
    # Clean Flatpak unused runtimes
    flatpak uninstall --unused -y
    
    # Clean distrobox if available
    if command -v distrobox >/dev/null; then
        echo "Cleaning distrobox images..."
        podman system prune -a -f --volumes
    fi
    
    # Clean journal logs older than 3 days
    sudo journalctl --vacuum-time=3d
    
    echo "Cleanup complete!"

# Show system information
[group('System')]
system-info:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "═══════════════════════════════════════════════════════════"
    echo "                    SYSTEM INFORMATION"
    echo "═══════════════════════════════════════════════════════════"
    
    echo "── OS Information ─────────────────────────────────────────"
    cat /etc/os-release | grep -E "NAME|VERSION|BUILD_ID"
    
    echo ""
    echo "── RPM-OSTree Status ──────────────────────────────────────"
    rpm-ostree status
    
    echo ""
    echo "── Hardware Information ───────────────────────────────────"
    echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
    
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits)"
    elif lspci | grep -i vga | grep -i amd >/dev/null; then
        echo "GPU: $(lspci | grep -i vga | grep -i amd | cut -d: -f3)"
    elif lspci | grep -i vga | grep -i intel >/dev/null; then
        echo "GPU: $(lspci | grep -i vga | grep -i intel | cut -d: -f3)"
    fi
    
    echo ""
    echo "── Disk Usage ─────────────────────────────────────────────"
    df -h / /home /var 2>/dev/null | grep -v tmpfs
    
    echo ""
    echo "═══════════════════════════════════════════════════════════"

# ───────────────────────────────────────────────
# DEVELOPMENT GROUP
# ───────────────────────────────────────────────

# Initialize a new project directory with common files
[group('Development')]
init-project PROJECT_NAME:
    #!/usr/bin/env bash
    set -euo pipefail
    
    mkdir -p "{{ PROJECT_NAME }}"
    cd "{{ PROJECT_NAME }}"
    
    # Initialize git
    git init
    
    # Create basic gitignore
    cat > .gitignore << 'EOF'
# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Dependencies
node_modules/
.npm
.yarn

# Build outputs
dist/
build/
*.tar.gz

# Environment
.env
.env.local
.env.*.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
EOF
    
    # Create basic README
    cat > README.md << EOF
# {{ PROJECT_NAME }}

## Description
Add project description here.

## Installation
Add installation instructions here.

## Usage
Add usage instructions here.

## Contributing
Add contributing guidelines here.

## License
Add license information here.
EOF
    
    # Create justfile
    cat > justfile << 'EOF'
# Project justfile

default:
    @just --list

# Install dependencies
install:
    echo "Add installation commands here"

# Run the project
run:
    echo "Add run commands here"

# Test the project
test:
    echo "Add test commands here"

# Build the project
build:
    echo "Add build commands here"

# Clean build artifacts
clean:
    echo "Add clean commands here"
EOF
    
    echo "Project '{{ PROJECT_NAME }}' initialized!"
    echo "Navigate to the directory with: cd {{ PROJECT_NAME }}"

# Create a backup of important dotfiles
[group('Development')]
backup-dotfiles:
    #!/usr/bin/env bash
    set -euo pipefail
    
    backup_dir="${HOME}/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    echo "Creating dotfiles backup in: $backup_dir"
    
    # List of important dotfiles to backup
    dotfiles=(
        ".gitconfig"
        ".bashrc"
        ".zshrc"
        ".config/fish"
        ".ssh/config"
        ".vimrc"
        ".tmux.conf"
        ".justfile"
    )
    
    for file in "${dotfiles[@]}"; do
        if [ -e "${HOME}/${file}" ]; then
            echo "Backing up: $file"
            cp -r "${HOME}/${file}" "$backup_dir/"
        fi
    done
    
    echo "Backup complete!"

# ───────────────────────────────────────────────
# UTILITIES GROUP
# ───────────────────────────────────────────────

# Show network information
[group('Utilities')]
network-info:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "── Network Information ────────────────────────────────────"
    echo "Hostname: $(hostname)"
    echo "Internal IP: $(hostname -I | awk '{print $1}')"
    
    if command -v curl >/dev/null; then
        echo "External IP: $(curl -s ifconfig.me)"
    fi
    
    echo ""
    echo "── Active Connections ─────────────────────────────────────"
    ip route | grep default
    
    echo ""
    echo "── Network Interfaces ─────────────────────────────────────"
    ip addr show | grep -E "^[0-9]|inet "

# Monitor system resources
[group('Utilities')]
monitor:
    #!/usr/bin/env bash
    set -euo pipefail
    
    if command -v btop >/dev/null; then
        btop
    elif command -v htop >/dev/null; then
        htop
    else
        top
    fi

# Generate a random password
[group('Utilities')]
genpass LENGTH="16":
    #!/usr/bin/env bash
    set -euo pipefail
    
    openssl rand -base64 {{ LENGTH }} | tr -d "=+/" | cut -c1-{{ LENGTH }}

# Show system logs
[group('Utilities')]
logs:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Recent system logs (last 50 lines):"
    sudo journalctl -n 50 --no-pager
    
    echo ""
    echo "For real-time logs, use: sudo journalctl -f"

# Reboot to BIOS/UEFI
[group('Utilities')]
reboot-to-bios:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Rebooting to BIOS/UEFI..."
    sudo systemctl reboot --firmware-setup

# Test network connectivity
[group('Utilities')]
network-test:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Testing network connectivity..."
    
    # Test DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
        echo "✓ DNS resolution working"
    else
        echo "✗ DNS resolution failed"
    fi
    
    # Test internet connectivity
    if ping -c 3 google.com >/dev/null 2>&1; then
        echo "✓ Internet connectivity working"
    else
        echo "✗ Internet connectivity failed"
    fi
    
    # Test speed (if speedtest-cli is available)
    if command -v speedtest-cli >/dev/null; then
        echo ""
        echo "Running speed test..."
        speedtest-cli --simple
    fi