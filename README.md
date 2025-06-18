# SoltrOS - Desktop Edition

A gaming-optimized immutable Linux distribution based on Universal Blue's base image, featuring MacBook hardware support, gaming enhancments, the latest Cinnamon Desktop, comprehensive package management, and developer-friendly tools.

*Inspired by [VenOS](https://github.com/Venefilyn/veneos) - bringing together the best of gaming and productivity.*

### Installation
Right now, the easiest way to get SoltrOS working is to download [Fedora Silverblue](https://fedoraproject.org/atomic-desktops/silverblue/download) and install it. Then, run:
```
sudo bootc switch ghcr.io/soltros/soltros-os:latest

sudo systemctl reboot
```
The "Latest" image will give you the experience that is suggested (Cosmic). However, if you'd like to check out other versions (that are still under development as well), you can. Just check the "packages" section.

## 🚀 Features

### 🎮 Gaming Ready
- **Gaming optimizations** with enhanced kernel parameters for performance
- **Controller support** for PlayStation, Xbox, Nintendo Switch Pro, Steam, and 8BitDo controllers
- **MangoHud** and **GameMode** integration for performance monitoring and optimization
- **Steam runtime optimizations** with proper GPU configurations
- **Optimized CPU governor** settings for gaming workloads

### 💻 MacBook Support
- **Thermal management** with `thermald` and `mbpfan` for optimal temperature control
- **Apple SMC support** via `applesmc` kernel module
- **Hardware-specific configurations** optimized for MacBook Pro models
- **Humidity-resistant thermal settings** for better longevity

### 📦 Triple Package Management
- **RPM-OSTree** (System packages) - Immutable base system
- **Flatpak** (Applications) - Sandboxed desktop applications
- **Homebrew** (Additional tools) - macOS-style package manager for Linux

### 🛠️ Developer Experience
- **Fish shell** as default with modern tooling integration
- **Just** command runner with extensive SoltrOS-specific recipes
- **Git integration** with SSH signing and useful aliases
- **Shell enhancements** with aliases, plugins, and modern CLI tools
- **Container signing** with cosign for security

### 🎨 Desktop Environment
- **Cosmic** with dark theme by default
- **Papirus icon theme** for a modern look
- **Custom branding** and SoltrOS identity
- **Optimized settings** for productivity and aesthetics

## 📋 Included Software

### System Packages (RPM)
- `fish` - Modern shell with autocompletion
- `gimp` - Image editing
- `tailscale` - Zero-config VPN
- `gamemode` & `mangohud` - Gaming performance tools
- `papirus-icon-theme` - Modern icon set
- `thermald` & `mbpfan` - Thermal management
- `lm_sensors` - Hardware monitoring

### Flatpak Applications
Over 40 pre-configured applications including:
- **Browsers**: Waterfox
- **Communication**: Discord, Telegram
- **Media**: VLC, Jellyfin Media Player, Clapper
- **Gaming**: Steam, Lutris, RetroArch, Heroic Games Launcher
- **Development**: Zed Editor, Podman Desktop
- **Productivity**: LibreOffice, Bitwarden
- **System Tools**: Flatseal, Mission Center, Warehouse

### Development Tools (Available via Homebrew)
Access to packages via Homebrew - all without affecting the base system.

## 🚀 Quick Start

### Installation

#### Method 1: Rebase from existing Fedora Atomic
```bash
sudo bootc switch ghcr.io/soltros/soltros-os:latest
```

#### Method 2: Fresh Installation
Use the provided ISO configuration to install directly.

### First Boot Setup

1. **Install Flatpaks**:
   ```bash
   just soltros-install-flatpaks
   ```

2. **Setup development environment**:
   ```bash
   just soltros-setup-cli
   ```

3. **Configure Git** (optional):
   ```bash
   just soltros-setup-git
   ```

4. **Install Homebrew** (optional):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

## 🛠️ Available Commands

SoltrOS includes a comprehensive set of `just` recipes for system management:

### Installation & Setup
```bash
just soltros-install-flatpaks    # Install all Flatpak applications
just soltros-setup-cli           # Setup shell configurations
just soltros-setup-git           # Configure Git with SSH signing
```
### System Configuration
```bash
just soltros-enable-amdgpu-oc    # Enable AMD GPU overclocking
```

### Standard Universal Blue Commands
All existing Universal Blue and Aurora commands are available:
```bash
just                             # List all available commands
just update                      # Update the system
just clean                       # Clean up the system
```

## 🔧 Customization

### Shell Configuration
SoltrOS automatically sets up:
- **Fish shell** with modern plugins
- **Aliases** for common tools (eza, bat, flatpak apps)
- **Environment variables** for optimal development experience
- **Tool integrations** for starship, atuin, zoxide, etc.

### Gaming Optimizations
Pre-configured settings include:
- Increased memory map areas (`vm.max_map_count = 2147483642`)
- Network optimizations for online gaming
- Controller udev rules for proper access
- CPU performance governor settings

### MacBook Optimizations
- Aggressive thermal management starting at 58°C
- Hardware sensor support via applesmc
- Optimized fan curves for humidity resistance

## 🔒 Security

- **Container signing** with cosign verification
- **Immutable base system** via rpm-ostree
- **Sandboxed applications** via Flatpak
- **Verified package sources** for all package managers

## 🏗️ Building

### Prerequisites
- Podman or Docker
- Just command runner

### Build locally
```bash
just build
```

### Build and push
```bash
just build
just push
```

## Server Image
The SoltrOS Server Edition is very much a work in progress. To install, simply set up Silverblue, and bootc swap to it: https://github.com/soltros/soltros-os-server

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the build locally
5. Submit a pull request

## 📝 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [VenOS](https://github.com/Venefilyn/veneos) for the inspiration and innovative approach to immutable gaming distributions
- [Universal Blue](https://github.com/ublue-os) for the excellent foundation
- [Fedora Project](https://fedoraproject.org/) for the underlying OS
- [Homebrew](https://brew.sh/) for cross-platform package management

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/soltros/soltros-os/issues)
- **Discussions**: [GitHub Discussions](https://github.com/soltros/soltros-os/discussions)

---

**SoltrOS** - Gaming meets productivity in an immutable, secure, and developer-friendly Linux distribution.
