#!/bin/bash
RED="\e[31m"
GREEN="\e[32m"
MAGENTA="\e[33m"
ENDCOLOR="\e[0m"

# Helper functions
logG() {
    echo -e "${GREEN}[INFO] $1${ENDCOLOR}"
}
logM() {
    echo -e "${MAGENTA}[INFO] $1${ENDCOLOR}"
}

error() {
    echo -e "${RED}[ERROR] $1${ENDCOLOR}" >&2
}

# Function to determine the distribution
get_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    else
        error "Unsupported OS"
        exit 1
    fi
}

clone_packages() {
  logG "Cloning packages..."
  while read -r repo dest; do
    [[ "$repo" =~ ^#.*$ || -z "$repo" ]] && continue

    # Expand tilde manually
    dest="${dest/#\~/$HOME}"

    if [ -d "$dest" ]; then
      logG "Skipping $dest (already exists)"
    else
      git clone "$repo" "$dest"
    fi
  done < clones.txt
}

run_curls() {
  logG "Running curl installs..."
  while read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    logG "Executing: $line"
    bash -lc "$line"  # runs in a login shell, loads .zshrc
  done < curl.txt
}


install_packages() {
    DISTRO=$(get_distro)
    case "$DISTRO" in
        ubuntu)
            logG "Installing packages on Ubuntu..."
            sudo apt update
            while read -r pkg; do
                [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue
                if ! dpkg -l | grep -q "^ii  $pkg"; then
                    logG "Installing package: $pkg"
                    sudo apt install -y "$pkg"
                else
                    error "Package $pkg is already installed"
                fi
            done < packages.txt
            ;;
        arch)
            logG "Installing packages on Arch Linux..."

            # Ensure yay is installed
            if ! command -v yay &>/dev/null; then
                logM "yay not found. Installing yay..."
                sudo pacman -S --needed --noconfirm git base-devel
                git clone https://aur.archlinux.org/yay.git /tmp/yay
                (cd /tmp/yay && makepkg -si --noconfirm)
                rm -rf /tmp/yay
            fi

            while read -r pkg; do
                [[ "$pkg" =~ ^#.*$ || -z "$pkg" ]] && continue

                if pacman -Qi "$pkg" &>/dev/null; then
                    error "Package $pkg is already installed"
                    continue
                fi

                if pacman -Si "$pkg" &>/dev/null; then
                    logG "Installing $pkg from official repos..."
                    sudo pacman -S --noconfirm --needed "$pkg"
                else
                    logG "Installing $pkg from AUR..."
                    yay -S --noconfirm --needed "$pkg"
                fi
            done < packages.txt
            ;;
        *)
            error "Unsupported Linux distribution: $DISTRO"
            exit 1
            ;;
    esac
}

# Symlink dotfiles
symlink_dotfiles() {
    DIR=$HOME/dotfiles
    DOTFILES=(
        ".config/tmux"
        ".config/bat"
        ".config/eww"
        ".config/hypr"
        ".config/nvim"
        ".config/omarchy"
        ".zshrc"
        # ".ideavimrc"
    )

    for dot in "${DOTFILES[@]}"; do
        TARGET="$HOME/$dot"
        SOURCE="$DIR/$dot"
        
        if [ -e "$TARGET" ]; then
            logM "Removing existing file/directory: $TARGET"
            rm -rf "$TARGET"
        fi
        
        logG "Creating symlink: $TARGET -> $SOURCE"
        ln -sf "$SOURCE" "$TARGET"
    done
}


# Main execution
logG "Starting dotfiles setup..."

clone_packages
run_curls
install_packages
symlink_dotfiles

source "$HOME/.nvm/nvm.sh"
nvm install 20.5.0

logG "Dotfiles setup complete!"
logM "Open a new terminal or run 'exec zsh' to start using your environment."

