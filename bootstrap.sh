#!/bin/bash
# bootstrap.sh – an automated Arch Linux bootstrap script
# This script sets up networking, updates your system,
# installs official packages, installs AUR packages (using yay),
# clones your dotfiles, creates config symlinks,
# sets up nvm/node, configures git, and switches your default shell to zsh.
#
# Review and adjust as needed.
#
# Usage:
#   chmod +x bootstrap.sh
#   ./bootstrap.sh
#
# Note: Do not run this script as root!

set -euo pipefail

############################
# Preliminary Checks
############################

# Ensure the script is not run as root.
if [ "$EUID" -eq 0 ]; then
    echo "Do not run this script as root. It will use sudo when needed."
    exit 1
fi

############################
# Functions
############################

# 1. Setup Networking
setup_network() {
    echo "==> Starting the iwd service..."
    sudo systemctl start iwd

    echo "==> Bringing up wlan0 interface..."
    sudo ip link set wlan0 up

    echo "==> NOTE: You may need to connect to your Wi‑Fi network using nmtui or iwctl."
    read -rp "Press Enter once you have a working network connection..."

    echo "==> Testing network connectivity..."
    if ! ping -c 3 8.8.8.8 &>/dev/null; then
        echo "Network connectivity test failed. Please check your connection and re-run the script."
        exit 1
    fi
    echo "Network connectivity OK."
}

# 2. Update the System
update_system() {
    echo "==> Updating system (pacman)..."
    sudo pacman -Syu --noconfirm
}

# 3. Install Official Packages with pacman
install_official_packages() {
    # List of packages from the official repositories.
    local packages=(
        iwd
        wmenu
        chromium
        tmux
        rust
        neovim-git
        tree-sitter
        mutt
        git
        base-devel
        python
        go
        curl
        tree
        fzf
        wget
        alacritty
    )
    echo "==> Installing official packages: ${packages[*]}"
    sudo pacman -S --needed --noconfirm "${packages[@]}"
}

# 4. Install Yay (AUR Helper)
install_yay() {
    if ! command -v yay &>/dev/null; then
        echo "==> Yay not found. Installing yay from the AUR..."
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        # The --noconfirm flag will assume defaults.
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
    else
        echo "==> Yay is already installed."
    fi
}

# 5. Install AUR Packages with yay
install_aur_packages() {
    # List of AUR packages (adjust as needed).
    local aur_packages=(
        ttf-iosevka-nerd
        fastfetch
        tree-sitter-cli-git
        nvm
        starship
        uv
        aichat
        github-cli-git
        1password
    )
    echo "==> Installing AUR packages: ${aur_packages[*]}"
    yay -S --needed --noconfirm "${aur_packages[@]}"
}

# 6. Clone Your Dotfiles Repository
clone_dotfiles() {
    if [ ! -d "$HOME/dotfiles" ]; then
        echo "==> Cloning dotfiles repository..."
        git clone https://github.com/jackmhny/dotfiles.git "$HOME/dotfiles"
    else
        echo "==> Dotfiles repository already exists at ~/dotfiles."
    fi
}

# 7. Create Configuration Symlinks
symlink_configs() {
    echo "==> Creating configuration symlinks..."

    # Zsh environment file
    ln -sf "$HOME/dotfiles/.zshenv" "$HOME/.zshenv"
    echo "  Linked .zshenv."

    # Alacritty config
    mkdir -p "$HOME/.config/alacritty"
    ln -sf "$HOME/dotfiles/alacritty/alacritty.arch.toml" "$HOME/.config/alacritty/alacritty.toml"
    echo "  Linked Alacritty config."

    # Sway config (if available)
    mkdir -p "$HOME/.config/sway"
    if [ -f /etc/sway/config ]; then
        cp /etc/sway/config "$HOME/.config/sway/config"
        echo "  Copied Sway config from /etc/sway."
    else
        echo "  /etc/sway/config not found. Skipping sway config."
    fi

    # Neovim config
    mkdir -p "$HOME/.config"
    ln -sf "$HOME/dotfiles/nvim" "$HOME/.config/nvim"
    echo "  Linked Neovim config."

    # Foot config
    mkdir -p "$HOME/.config/foot"
    ln -sf "$HOME/dotfiles/foot/foot.arch.ini" "$HOME/.config/foot/foot.ini"
    echo "  Linked Foot config."

    # Zsh config (.zshrc)
    if [ -f "$HOME/dotfiles/.zsh/.zshrc" ]; then
        ln -sf "$HOME/dotfiles/.zsh/.zshrc" "$HOME/.zshrc"
        echo "  Linked .zshrc."
    else
        echo "  No .zshrc found in dotfiles/.zsh. Skipping."
    fi
}

# 8. Setup nvm and Install Node.js
setup_nvm_and_node() {
    echo "==> Setting up nvm and installing Node.js..."
    # nvm is installed via AUR; it typically installs into ~/.nvm.
    export NVM_DIR="$HOME/.nvm"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        # Load nvm into the current shell session.
        \. "$NVM_DIR/nvm.sh"
        nvm install node
        nvm use node
        echo "  Node.js installed and activated."
    else
        echo "  nvm not found at $NVM_DIR. Please check the nvm installation."
    fi
}

# 9. Configure Git Global Settings
configure_git() {
    echo "==> Configuring global git settings..."
    git config --global user.email "jacksmahoney@gmail.com"
    git config --global user.name "Jack Mahoney (arch)"
}

# 10. Change Default Shell to zsh (if not already)
change_default_shell() {
    local current_shell
    current_shell=$(basename "$SHELL")
    if [ "$current_shell" != "zsh" ]; then
        echo "==> Changing default shell to zsh..."
        chsh -s "$(which zsh)"
        echo "  Default shell changed. (You may need to log out/in for the change to take effect.)"
    else
        echo "==> Default shell is already zsh."
    fi
}

############################
# Main Execution
############################

main() {
    echo "======================================"
    echo "   Arch Linux Bootstrap Script"
    echo "======================================"

    setup_network
    update_system
    install_official_packages
    install_yay
    install_aur_packages
    clone_dotfiles
    symlink_configs
    setup_nvm_and_node
    configure_git
    change_default_shell

    echo "======================================"
    echo "Bootstrap complete!"
    echo "Please restart your terminal session to ensure all changes take effect."
}

# Run the main function
main

