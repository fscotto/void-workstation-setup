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
  fi
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

  sudo xbps-install -Syu "$@" >>"$LOG_FILE" 2>&1
  return 0 # Indicate success
}

enable_service() {
  service="$1"
  if [ -e "/var/service/$service" ]; then
    warn "Service $service already enabled"
    return 0
  fi

  info "Enable $service service"
  if sudo ln -sf "/etc/sv/$service" /var/service/; then
    warn "Failed to enable $service service"
    return 0
  fi
  return 0
}
