#!/bin/bash

RED="\e[31m"
log() {
    echo -e "${RED}[ERROR] $1${ENDCOLOR}"
}
# Git repos for things

cat <<EOF | while read repo dest; do
https://github.com/jimeh/tmuxifier.git ~/.tmuxifier
https://github.com/junegunn/fzf-git.sh.git ~/.fzf-git
https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
EOF
  dest="${dest/#\~/$HOME}"
  if [ ! -d "$dest" ]; then
    git clone "$repo" "$dest"
  fi
done

# nvm and node
if [ ! -d "$HOME/.nvm" ]; then 
  mkdir -p ~/.nvm && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
  nvm install 22.21.0
  nvm use 22.21.0
fi


# rust
if ! command -v rustc >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi

# Other packages -- General
sudo pacman -Sy --needed starship bat eza lazygit lazydocker intel-media-driver libva-utils tree dysk

# Check if AUR is reachable
if curl -s --head https://aur.archlinux.org | grep "200 OK" > /dev/null; then
  yay -S --needed --noconfirm ttf-font-awesome ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols
  yay -S --needed --noconfirm awsvpnclient
  yay -S --needed --noconfirm keeper-password-manager
else
  log "AUR is currently down. Can't install AUR packages right now."
fi


