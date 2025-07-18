#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/logging.sh"

OPENSSL_CONF="/etc/ssl/openssl.cnf"
BACKUP_CONF="$OPENSSL_CONF.bak.$(date +%Y%m%d%H%M%S)"

info "Checking if OpenSSL legacy renegotiation is already enabled..."

# Controlla se la configurazione è già presente
if sudo grep -Pzo "\[system_default_sect\][^\[]*Options\s*=\s*UnsafeLegacyRenegotiation" "$OPENSSL_CONF" >/dev/null; then
  success "OpenSSL legacy renegotiation is already enabled."
  exit 0
fi

info "Backing up original OpenSSL config to $BACKUP_CONF"
if sudo cp "$OPENSSL_CONF" "$BACKUP_CONF"; then
  success "Backup created successfully."
else
  error "Failed to create backup of $OPENSSL_CONF"
  exit 1
fi

info "Appending legacy renegotiation settings to $OPENSSL_CONF"
if sudo tee -a "$OPENSSL_CONF" >/dev/null <<'EOF'; then

# Enable legacy renegotiation
[openssl_init]
ssl_conf = ssl_sect

[ssl_sect]
system_default = system_default_sect

[system_default_sect]
Options = UnsafeLegacyRenegotiation
EOF
  success "OpenSSL legacy renegotiation enabled successfully."
else
  error "Failed to update OpenSSL config."
  exit 1
fi
