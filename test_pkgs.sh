#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${LOG_FILE:-install.log}"

source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/functions.sh"

# Function to check if a package exists in Void Linux official binary repositories.
# This ensures we only try to install packages directly available via xbps-install.
package_exists_void_repo() {
  xbps-query -Rs "^$1$" &>/dev/null
}

info "Installing base system packages from official Void Linux repositories..."

PACKAGES=(
  alsa-pipewire
  alsa-utils
  argocd-bin
  arp-scan
  base-devel
  base-system
  bat
  bluez
  bluez-alsa
  bluez-utils
  blueman
  btop
  catppuccin-gtk-theme
  clang
  clang-tools-extra
  cmatrix
  cmake
  cronie
  curl
  dbus-elogind
  dbeaver
  dconf-editor
  delta
  devtoolbox
  dmenu
  docker
  duf
  dwarves
  elogind
  entr
  exercism
  eza
  fastfetch
  fd
  ffmpegthumbnailer
  filezilla
  firefox
  foot
  freefilesync-bin
  fuzzel
  fzf
  gcc
  gcolor3
  gdb
  gh
  git
  git-delta
  git-extras
  glab-bin
  glow
  glow-bin
  gnome-boxes
  gnupg
  go
  grim
  grub-x86_64-efi
  gvfs
  helm
  htop
  httpie
  hugo
  hwinfo
  hyprland
  hyprpaper
  inotify-tools
  intel-media-driver
  jmeter
  jq
  k9s
  kitty
  kubectl
  koodo-reader
  lazydocker
  lazygit
  libasan
  libsanitizer-devel
  linux-headers
  lsof
  ltrace
  luarocks
  mako
  make
  masterpdfeditor-bin
  maven
  mesa-dri
  minikube-bin
  mise
  mlocate
  moar-bin
  moreutils
  nasm
  neovim
  net-tools
  network-manager-applet
  networkmanager
  ninja
  nm-connection-editor
  onlyoffice-desktopeditors
  openssh
  openshift-cli-bin
  operator-sdk-bin
  papirus-icon-theme
  papirus-icon-theme-dark
  pavucontrol
  pinentry-gtk
  pinentry-tty
  pipewire
  pipewire-pulse
  pipx
  pkgconf
  polkit
  putty
  python-black
  python-flake8
  python-ipython
  python-isort
  python-mypy
  python-pip
  python-pipx
  python-pylint
  python-pytest
  python-virtualenv
  python3-virtualenv
  qalculate-gtk
  quarkus
  qemu
  ripgrep
  rpi-imager
  rsync
  rustup
  seahorse
  slurp
  solaar
  spotify
  spring-boot
  starship
  stow
  strace
  sushi
  sway
  swayidle
  swaylock
  task
  telegram-desktop
  thunar
  thunderbird
  tmux
  ttf-cascadia-code-nerd
  ttf-firacode-nerd
  ttf-jetbrains-mono-nerd
  ttf-roboto-mono-nerd
  uar
  ugrep
  unar
  unzip
  valgrind
  vim
  vlc
  waybar
  wget
  wireplumber-elogind
  wlogout
  xclip
  xdg-desktop-portal-gtk
  xdg-desktop-portal-wlr
  xorg-fonts
  xournalpp
  xsel
  xterm
  yarn
  zoxide
  zsh
)

# Filter out non-existent packages from official repos
declare -a VALID_PACKAGES=()
for pkg in "${PACKAGES[@]}"; do
  if package_exists_void_repo "$pkg"; then
    VALID_PACKAGES+=("$pkg")
  else
    warn "Void Linux: Package '$pkg' not found in official binary repositories. Skipping."
  fi
done

# Install officially available packages
for pkg in "${VALID_PACKAGES[@]}"; do
  install_pkg "$pkg" # Assumes install_pkg uses xbps-install
done

info "Installing additional applications, focusing on Void Linux build methods..."
