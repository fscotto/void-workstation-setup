#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# -------------------------------------------------------
# Nerd Fonts Installer Script
# -------------------------------------------------------

source "$(dirname "${BASH_SOURCE[0]}")/../lib/logging.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/functions.sh"

FONT_DIR="/usr/share/fonts/nerd-fonts"

# Check if a font is already installed
check_installed_font() {
  local font_name="${1}"
  local entries_num
  entries_num=$(find "${FONT_DIR}" -iname "${font_name}*" -type f 2>/dev/null | wc -l)
  ((entries_num > 0)) && echo "Y" || echo "N"
}

info "Starting Nerd Fonts installation..."

# --- Privilege Elevation ---
if [[ $EUID -ne 0 ]]; then
  info "Elevating privileges with sudo..."
  exec sudo bash "$0" "$@"
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

fonts_installed=()
for font in "${!fonts[@]}"; do
  if [[ "$(check_installed_font "$font")" == "N" ]]; then
    url="${fonts[$font]}"
    info "Downloading and installing Nerd Font: $font"
    wget -q "$url" -O "${font}.zip"
    unzip -q "${font}.zip" -d "${font}"
    find "${font}" -type f \( -iname "*.ttf" -o -iname "*.otf" \) -exec mv -v {} "${FONT_DIR}/" \;
    rm -rf "${font}" "${font}.zip"
    fonts_installed+=("$font")
  else
    info "Nerd Font $font already installed. Skipping."
  fi
done

if [ ${#fonts_installed[@]} -gt 0 ]; then
  info "Updating font cache..."
  fc-cache -fv
  info "Fonts installed: ${fonts_installed[*]} ✔"
else
  info "No new fonts were installed. All selected fonts are already present. ✅"
fi

info "Nerd Fonts installation completed."
