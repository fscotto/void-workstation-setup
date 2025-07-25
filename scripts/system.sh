#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${LOG_FILE:-install.log}"

source "$SCRIPT_DIR/../lib/logging.sh"
source "$SCRIPT_DIR/../lib/functions.sh"

info "Add repositories non-free and multilib"

install_pkg "void-repo-nonfree" "void-repo-multilib" "void-repo-multilib-nonfree"

PACKAGES=(
  alsa-pipewire
  alsa-utils
  arp-scan
  apache-maven
  base-devel
  bat
  bluez
  bluez-alsa
  blueman
  btop
  clang
  clang-tools-extra
  cmatrix
  cmake
  cronie
  curl
  dbus-elogind
  dbeaver
  delta
  dmenu
  docker
  duf
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
  fuzzel
  fzf
  gcc
  gdb
  git
  git-extras
  github-cli
  glab
  glow
  gnupg
  go
  grim
  gvfs
  htop
  hugo
  hwinfo
  inotify-tools
  intel-media-driver
  jq
  k9s
  kubernetes-helm
  kubectl
  lazydocker
  lazygit
  libsanitizer-devel
  linux-headers
  lsof
  ltrace
  luarocks
  mako
  make
  mesa-dri
  mise
  mlocate
  moar
  moreutils
  nasm
  neovim
  net-tools
  network-manager-applet
  NetworkManager
  ninja
  openssh
  papirus-icon-theme
  pavucontrol
  pinentry-gtk
  pinentry-tty
  pipewire
  pkgconf
  polkit
  polkit-elogind
  python3-flake8
  python3-ipython
  python3-isort
  python3-mypy
  python3-pip
  python3-pipx
  python3-pylint
  python3-pytest
  python3-virtualenv
  qemu
  rclone
  ripgrep
  rpi-imager
  rsync
  rustup
  slurp
  starship
  stow
  strace
  sway
  swayidle
  swaylock
  telegram-desktop
  Thunar
  thunderbird
  tmux
  ugrep
  unar
  unzip
  valgrind
  vim
  vlc
  Waybar
  wget
  wireplumber-elogind
  wlogout
  xclip
  xdg-desktop-portal-gtk
  xdg-desktop-portal-wlr
  xorg-fonts
  xournalpp
  xsel
  xtools
  yarn
  zoxide
  zsh
)

info "Installing base system packages..."
install_pkg "${PACKAGES[@]}"

info "Installing additional apps from source..."

VOID_PACKAGES_REPO="https://github.com/void-linux/void-packages.git"
VOID_PACKAGES_DIR="$HOME/void-packages"
if [ ! -d "$VOID_PACKAGES_DIR" ]; then
  info "Clone void-packages repository from GitHub"
  git clone "$VOID_PACKAGES_REPO" "$VOID_PACKAGES_DIR"
fi

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

    if [ -d "$VOID_PACKAGES_DIR" ]; then
      (
        cd "$VOID_PACKAGES_DIR" &&
          echo "XBPS_ALLOW_RESTRICTED=yes" >etc/conf &&
          ./xbps-src binary-bootstrap &&
          ./xbps-src pkg "$pkg" &&
          sudo xbps-install --repository="$VOID_PACKAGES_DIR/hostdir/binpkgs" "$pkg"
      ) >>"$LOG_FILE" 2>&1 ||
        warn "Void Linux: Failed to build or install $pkg via xbps-src. Check void-packages setup and 'XBPS_ALLOW_RESTRICTED'."
    else
      warn "Void Linux: 'void-packages' repository not found at '$VOID_PACKAGES_DIR'. Cannot build $pkg automatically."
      warn "To install $pkg, clone void-packages (git clone $VOID_PACKAGES_REPO) and build manually with 'xbps-src pkg $pkg'."
    fi
    ;;
  "postman")
    warn "Void Linux: Postman ($pkg) is NOT available in official repositories or void-packages. It requires manual installation (downloading the tarball) or a community-maintained template if one exists for xbps-src."
    warn "Refer to Postman's official website for manual installation instructions."

    #TODO: procedure for installing Postman
    ;;
  *)
    warn "Void Linux: Unknown APP_PACKAGE '$pkg'. Manual inspection required."
    ;;
  esac
done

success "All additional applications installed."

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

# Define the expected home directory for asdf.
asdf_home="$HOME/.asdf"
mise_data_target="${MISE_DATA_DIR:-$HOME/.local/share/mise}"

# --- Main logic to manage the ~/.asdf symlink ---

# 1. Handle old asdf-vm directory: if .asdf is a directory, rename it.
if [ -d "$asdf_home" ] && [ ! -L "$asdf_home" ]; then
  warn "Old ASDF directory found. Renaming to .asdf.old"
  mv "$asdf_home" "$asdf_home.old"
fi

# 2. Create or update the symlink.
#    - If $asdf_home does not exist, it creates it.
#    - If $asdf_home exists and is a file (not dir/symlink), it removes it and creates.
#    - If $asdf_home exists and is a symlink (correct or not), it updates/recreates it.
#    - The only case this does NOT handle is if $asdf_home was a directory (handled above).
ln -sfn "$mise_data_target" "$asdf_home"

# 3. Provide feedback based on the outcome.
if [ -L "$asdf_home" ] && [ "$(readlink "$asdf_home")" = "$mise_data_target" ]; then
  # Check if the symlink now exists and points correctly
  success "Symlink created/ensured: ~/.asdf → $mise_data_target"
else
  # This 'else' would only be hit if ln -sfn failed for some reason (e.g., permissions)
  # or if $asdf_home somehow became a directory again after 'mv'.
  warn "Could not ensure symlink ~/.asdf points to $mise_data_target. Manual inspection required."
fi

success "Mise setup completed successfully."

info "Enable services"
sudo mkdir -p /etc/pipewire/pipewire.conf.d/
sudo ln -sf /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/
sudo ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/

enable_service bluez-alsa
enable_service bluetoothd
enable_service cronie
enable_service docker
enable_service elogind
enable_service polkitd

info "Configuring $USER groups (docker, bluetooth)"

sudo gpasswd -a $USER docker
sudo gpasswd -a $USER bluetooth

success "Added $USER to groups docker and bluetooth"
