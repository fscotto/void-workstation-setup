#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# -------------------------------------------------------
# Nerd Fonts Installer Script
#
# Downloads and installs selected Nerd Fonts
# into the system fonts directory if not already present.
# Refreshes font cache at the end.
# -------------------------------------------------------

source "$(dirname "${BASH_SOURCE[0]}")/../lib/logging.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/functions.sh"

FONT_DIR=/usr/share/fonts/nerd-fonts

# Function to check if a font is already installed by searching FONT_DIR
check_installed_font() {
  local font_name="${1}"
  local entries_num
  entries_num=$(find "${FONT_DIR}" -iname "${font_name}*" 2>/dev/null | wc -l)
  ((entries_num > 0)) && echo "Y" || echo "N"
}

info "Starting Nerd Fonts installation..."

# --- Privilege Elevation ---
# Checks if the script is run as root and re-executes with sudo if not.
if [[ $EUID -ne 0 ]]; then
  info "Elevating privileges with sudo..."
  sudo bash "$0" "$@"
  exit $?
fi

mkdir -p "${FONT_DIR}"
cd /tmp || {
  error "Failed to change directory to /tmp"
  exit 1
}

declare -A fonts=(
  ["JetBrainsMono"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"
  ["FiraCode"]="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip"
)

fonts_already_installed=()
for font in "${!fonts[@]}"; do
  if [[ "$(check_installed_font "$font")" == "N" ]]; then
    url="${fonts[$font]}"
    info "Downloading and installing Nerd Font: $font"
    wget -q "$url" -O "${font}.zip"
    unzip -q "${font}.zip" -d "${font}"
    mv -v "${font}" "${FONT_DIR}/"
    rm -f "${font}.zip"
    fonts_already_installed+=("$font")
  else
    info "Nerd Font $font already installed. Skipping."
  fi
done

if [ ${#fonts_already_installed[@]} -gt 0 ]; then
  info "Fonts already installed: $(
    IFS=' '
    echo "${fonts_already_installed[*]}"
  ) ✔"
else
  info "Updating font cache..."
  fc-cache -fv
fi

cd - >/dev/null || exit
info "Nerd Fonts installation completed."
