#!/bin/bash

# Git repos for things

cat <<EOF | while read repo dest; do
https://github.com/jimeh/tmuxifier.git ~/.tmuxifier
https://github.com/junegunn/fzf-git.sh.git ~/.fzf-git
https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
EOF
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
sudo pacman -Sy --needed starship bat eza lazygit lazydocker instal-media-driver libva-utils
yay -S --needed --noconfirm ttf-font-awesome waybar ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols

# Other packages -- Work
sudo pacman -Sy --needed okta keeper-password-manager
yay -S --needed --noconfirm awsvpnclient

