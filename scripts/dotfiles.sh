#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${LOG_FILE:-install.log}"
source "$SCRIPT_DIR/../lib/logging.sh"

info "Configuring dotfiles..."

# Install Oh My Zsh if not installed
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >>"$LOG_FILE" 2>&1 && success "Oh My Zsh installed" || {
    error "Failed to install Oh My Zsh"
    exit 1
  }
else
  info "Oh My Zsh already installed"
fi

for file in "$HOME/.zshrc" "$HOME/.zshenv"; do
  if [[ -f "$file" && ! -L "$file" && ! -e "${file}.bak" ]]; then
    mv "$file" "${file}.bak"
    info "Backed up $(basename "$file") to $(basename "${file}.bak")"
  fi
done

# Change default shell to zsh if not already set and if zsh exists
if command -v zsh &>/dev/null; then
  if [[ "$SHELL" != "$(command -v zsh)" ]]; then
    info "Changing default shell to zsh for user $USER"
    chsh -s "$(command -v zsh)" && success "Default shell changed to zsh" || warn "Failed to change default shell"
  else
    info "Default shell is already zsh"
  fi
else
  warn "zsh is not installed, skipping shell change"
fi

# Test file ~/.config/background.jpg exists, otherwise copy ../data/background.jpg
if [[ ! -e "$HOME/.config/background.jpg" ]]; then
  info "Copy wallpaper in $HOME/.config"
  cp "$SCRIPT_DIR/../data/background.jpg" "$HOME/.config"
fi

DOTFILES_REPO="https://github.com/fscotto/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

if [[ ! -d "$DOTFILES_DIR" ]]; then
  info "Cloning dotfiles repository"
  git clone --recursive "$DOTFILES_REPO" "$DOTFILES_DIR" >>"$LOG_FILE" 2>&1 && success "Dotfiles repo cloned" || {
    error "Error cloning dotfiles"
    exit 1
  }
else
  info "Dotfiles repo already exists, updating"
  (cd "$DOTFILES_DIR" && git pull) >>"$LOG_FILE" 2>&1 && success "Dotfiles repo updated" || warn "Error updating dotfiles"
fi

if ! command -v stow &>/dev/null; then
  info "Installing stow to manage dotfiles"
  xbps-install -S --noconfirm stow >>"$LOG_FILE" 2>&1 && success "stow installed" || {
    error "Error installing stow"
    exit 1
  }
fi

info "Applying selected dotfiles with stow"

# List only the dotfiles directories you want to install
declare -a DOTFILES_TO_INSTALL=(
  "bat"
  "fastfetch"
  "foot"
  "fuzzel"
  "git"
  "lazygit"
  "mako"
  "nvim"
  "starship"
  "sway"
  "tmux"
  "vim"
  "waybar"
  "zsh"
)

cd "$DOTFILES_DIR" || {
  error "Cannot cd to $DOTFILES_DIR"
  exit 1
}

for dotfile in "${DOTFILES_TO_INSTALL[@]}"; do
  if [[ -d "$dotfile" ]]; then
    info "Stowing $dotfile"
    stow --dotfiles -R --dir "$DOTFILES_DIR" --target="$HOME" "$dotfile" >>"$LOG_FILE" 2>&1 && success "Stowed $dotfile" || warn "Failed to stow $dotfile"
  else
    warn "Dotfile directory $dotfile not found, skipping"
  fi
done

success "Dotfiles configuration completed"
