#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${LOG_FILE:-install.log}"

source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/functions.sh"

info "Installing base system packages..."

info "Install additional repositories non-free and multilib"

install_pkg "void-repo-nonfree" "void-repo-multilib" "void-repo-multilib-nonfree"

# TODO: remove from list the packages that not exists
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

for pkg in "${PACKAGES[@]}"; do
  install_pkg "$pkg"
done

info "Installing all development additional apps..."

# Applications that require building from void-packages (xbps-src)
# or specific manual handling unique to their distribution.
APP_PACKAGES=(
  # Packages that can be built via xbps-src from void-packages
  # Note: building from source can take time and requires the void-packages repo.
  # For restricted packages like this, XBPS_ALLOW_RESTRICTED=yes is required.
  intellij-idea-ultimate-edition

  # Packages NOT available in official void-packages and require manual steps.
  # These are listed here for awareness but require user intervention.
  postman
)

# Process APP_PACKAGES with Void Linux-specific instructions
for pkg in "${APP_PACKAGES[@]}"; do
  case "$pkg" in
  "intellij-idea-ultimate-edition")
    info "Void Linux: Attempting to build and install $pkg via xbps-src."
    info "This requires the 'void-packages' Git repository and 'XBPS_ALLOW_RESTRICTED=yes'."
    # Example xbps-src command (uncomment and configure if void-packages is set up):
    # VOID_PACKAGES_DIR="$HOME/void-packages" # Adjust this path to your void-packages clone
    # if [ -d "$VOID_PACKAGES_DIR" ]; then
    #   (cd "$VOID_PACKAGES_DIR" && XBPS_ALLOW_RESTRICTED=yes ./xbps-src pkg "$pkg" && sudo xbps-install --repository="$VOID_PACKAGES_DIR/hostdir/binpkgs" "$pkg") >>"$LOG_FILE" 2>&1 || warn "Void Linux: Failed to build or install $pkg via xbps-src. Check void-packages setup and 'XBPS_ALLOW_RESTRICTED'."
    # else
    #   warn "Void Linux: 'void-packages' repository not found at '$VOID_PACKAGES_DIR'. Cannot build $pkg automatically."
    #   warn "To install $pkg, clone void-packages (git clone https://github.com/void-linux/void-packages.git) and build manually with 'xbps-src pkg $pkg'."
    # fi
    ;;
  "postman")
    warn "Void Linux: Postman ($pkg) is NOT available in official repositories or void-packages. It requires manual installation (downloading the tarball) or a community-maintained template if one exists for xbps-src."
    warn "Refer to Postman's official website for manual installation instructions."
    ;;
  *)
    warn "Void Linux: Unknown APP_PACKAGE '$pkg'. Manual inspection required."
    ;;
  esac
done

# --- Mise configuration and plugin installation ---
info "Installing Mise core plugins and tools..."
plugins=(
  java
)
for plugin in "${plugins[@]}"; do
  info "Installing Mise plugin: $plugin"
  mise use -g -y "$plugin" >>"$LOG_FILE" 2>&1 || warn "Failed to install Mise plugin: $plugin"
done

info "Installing pinned versions of Java and Python..."
mise install -y java@temurin-17 >>"$LOG_FILE" 2>&1 || warn "Failed to install java@temurin-17"
mise install -y python@3.12 >>"$LOG_FILE" 2>&1 || warn "Failed to install python@3.12"

asdf_home="$HOME/.asdf"
if [ -d "$asdf_home" ]; then
  warn "Old ASDF directory found. Renaming to .asdf.old"
  mv "$asdf_home" "$asdf_home.old"
elif [ -e "$asdf_home" ]; then
  warn "Conflicting ASDF file found. Removing."
  rm -f "$asdf_home"
fi

if [[ ! -e "$HOME/.asdf" ]]; then
  ln -sfn "${MISE_DATA_DIR:-$HOME/.local/share/mise}" "$HOME/.asdf"
  success "Symlink created: ~/.asdf → ${MISE_DATA_DIR:-$HOME/.local/share/mise}"
else
  warn "Symlink ~/.asdf already exists"
fi

success "Mise setup completed successfully."

success "All development tools and applications installed."
