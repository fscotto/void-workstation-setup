#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${LOG_FILE:-install.log}"
source "$SCRIPT_DIR/lib/logging.sh"

info "🔧 Starting complete Void Linux setup"

# Function to run a script with logging and error handling
run_script() {
  local script_path="$1"
  info "Running script: $script_path"
  if bash "$script_path"; then
    success "Completed: $script_path"
  else
    error "Error occurred while running $script_path"
    exit 1
  fi
}

# List of scripts to run in order
SCRIPTS=(
  "$SCRIPT_DIR/scripts/system.sh"
  "$SCRIPT_DIR/scripts/nerdfonts.sh"
  "$SCRIPT_DIR/scripts/dotfiles.sh"
  "$SCRIPT_DIR/scripts/openssl-legacy.sh"
  "$SCRIPT_DIR/scripts/setup-tpm2.sh"
)

for script in "${SCRIPTS[@]}"; do
  if [[ -f "$script" && -x "$script" ]]; then
    run_script "$script"
  else
    warn "Script missing or not executable: $script"
  fi
done

success "✅ Void Linux setup completed successfully"
