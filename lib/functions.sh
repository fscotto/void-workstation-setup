#!/usr/bin/env bash

IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/logging.sh"

is_installed?() {
  local package_name="$1"
  if xbps-query --list-pkgs | awk '{ print $2 }' | xargs -n1 xbps-uhelper getpkgname | grep -E "^$package_name$" &>/dev/null; then
    return 0
  else
    return 1
}

# install_pkg() - Installs multiple Void Linux packages at once.
# Arguments: Takes a space-separated list of package names as arguments.
# Example: install_pkg "package1" "package2" "package3"
# Or: install_pkg "${PACKAGES[@]}"
install_pkg() {
  # Ensure at least one package name is provided
  if [ "$#" -eq 0 ]; then
    warn "No packages provided to install_pkg function."
    return 1
  fi

  local pkgs_to_install=()
  local pkgs_already_installed=()

  # Separate packages into those to install and those already present
  for pkg in "$@"; do
    if is_installed? "$pkg"; then
      pkgs_already_installed+=("$pkg")
    else
      pkgs_to_install+=("$pkg")
    fi
  done

  # Log already installed packages
  if [ ${#pkgs_already_installed[@]} -gt 0 ]; then
    info "Packages already installed: $(IFS=' '; echo "${pkgs_already_installed[*]}") ✔"
  fi

  # Install packages that are not already present
  if [ ${#pkgs_to_install[@]} -gt 0 ]; then
    info "Installing packages: $(IFS=' '; echo "${pkgs_to_install[*]}")"
    # Use -y for non-interactive installation (assumes 'yes' to prompts)
    # Use -Syu to sync, update, and then install (good practice before installing new packages)
    if sudo xbps-install -Syu "${pkgs_to_install[@]}" >>"$LOG_FILE" 2>&1; then
      success "Successfully installed: $(IFS=' '; echo "${pkgs_to_install[*]}")"
    else
      warn "Failed to install some packages. Check $LOG_FILE for details."
      warn "Packages that failed: $(IFS=' '; echo "${pkgs_to_install[*]}")" # Re-list for clarity
      return 1 # Indicate failure
    fi
  else
    info "All specified packages are already installed. Nothing to do."
  fi
  return 0 # Indicate success
}
