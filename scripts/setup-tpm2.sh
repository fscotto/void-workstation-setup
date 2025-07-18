#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

# --- Script Directory and Logging Setup ---
# Define SCRIPT_DIR to correctly source the logging script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define the log file path. This will override the default 'install.log' from logging.sh
# if you want a specific log file for this script.
LOG_FILE="/var/log/void-luks-tpm.log"

# Source the external logging functions.
source "$SCRIPT_DIR/../lib/logging.sh"

# --- Privilege Elevation ---
# Checks if the script is run as root and re-executes with sudo if not.
if [[ $EUID -ne 0 ]]; then
  info "Elevating privileges with sudo..."
  sudo bash "$0" "$@"
  exit $?
fi

# --- Global Variables ---
# PCRs (Platform Configuration Registers) to use for TPM sealing.
# Common PCRs for non-Secure Boot systems are 0, 1, 2, 3, 4, 5.
# PCR 7 is typically for Secure Boot state, which is disabled in your setup.
# You can adjust this list as needed.
tpm_pcrs="0+1+2+3+4+5"

# --- Function to find all LUKS devices ---
# Uses blkid to list all devices identified as LUKS.
find_luks_devices() {
  info "Searching for LUKS devices..."
  # mapfile reads lines from stdin into an array
  mapfile -t devices < <(blkid -t TYPE=crypto_LUKS -o device)
  echo "${devices[@]}" # Return devices as space-separated string
}

# --- Function to choose a LUKS device from a list ---
# Prompts the user to select a LUKS device if multiple are found.
choose_luks_device() {
  local devices=("$@") # Array of devices passed as arguments

  if ((${#devices[@]} == 0)); then
    warn "No LUKS devices found."
    echo ""
    return 1 # Indicate failure
  elif ((${#devices[@]} == 1)); then
    info "One LUKS device found: ${devices[0]}"
    echo "${devices[0]}" # Return the single device
    return 0             # Indicate success
  else
    info "Multiple LUKS devices found:"
    # List devices with numbers for user selection
    for i in "${!devices[@]}"; do
      info "  $((i + 1))) ${devices[i]}"
    done
    while true; do
      read -rp "Choose the device number to use: " choice
      # Validate user input: must be a number within the valid range
      if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && ((choice >= 1 && choice <= ${#devices[@]})); then
        echo "${devices[$((choice - 1))]}" # Return the selected device
        return 0                           # Indicate success
      else
        warn "Invalid choice, please enter a number between 1 and ${#devices[@]}."
      fi
    done
  fi
}

# --- Function to check for TPM device existence ---
# Checks if a TPM device (tpm0) is present and accessible.
tpm_device_exists() {
  info "Checking for TPM device..."
  # Check if /sys/class/tpm exists and contains any entries
  if [[ -d /sys/class/tpm ]] && compgen -G "/sys/class/tpm/*" >/dev/null; then
    info "TPM device found in /sys/class/tpm."
    return 0
  fi

  # Or check if /dev/tpm0 exists and is a character device
  if [[ -c /dev/tpm0 ]]; then
    info "TPM device found at /dev/tpm0."
    return 0
  fi

  warn "No TPM device found or accessible."
  return 1
}

# --- Function to configure dracut for TPM2 ---
# Modifies dracut configuration to include the tpm2 module and regenerates initramfs.
configure_dracut() {
  info "Configuring dracut for Void Linux..."
  local dracut_conf_snippet="/etc/dracut.conf.d/tpm2.conf"
  local dracut_modules_dir="/usr/lib/dracut/modules.d"

  # Ensure the dracut modules directory exists (standard for dracut)
  if [[ ! -d "$dracut_modules_dir" ]]; then
    error "Dracut modules directory '$dracut_modules_dir' not found. Is dracut installed correctly?"
  fi

  # Create dracut snippet config file for TPM2 if not already present
  if [[ ! -f "$dracut_conf_snippet" ]]; then
    info "Creating $dracut_conf_snippet to enable 'tpm2' module."
    echo 'add_dracutmodules+=" tpm2 "' >"$dracut_conf_snippet"
  else
    warn "'$dracut_conf_snippet' already exists. Skipping creation."
  fi

  info "Regenerating initramfs with dracut. This may take some time..."
  # Use --hostonly for smaller initramfs, and --force to overwrite existing ones.
  # Output is redirected to the log file.
  dracut --force --hostonly --kver "$(uname -r)" >>"$LOG_FILE" 2>&1
  if [[ $? -ne 0 ]]; then
    error "Dracut command failed. Check '$LOG_FILE' for details."
  fi
  success "Updated initramfs with 'tpm2' module."
}

# --- Main TPM Module Configuration Function ---
# Orchestrates the TPM2 enrollment and crypttab modification.
configure_tpm_module() {
  info "Starting TPM2 configuration."

  # Find and select the LUKS device
  mapfile -t luks_devices_found < <(find_luks_devices)
  local luks_device=$(choose_luks_device "${luks_devices_found[@]}")

  if [[ -z "$luks_device" ]]; then
    error "No LUKS device selected or found. Exiting."
  fi

  info "Proceeding with LUKS partition: $luks_device"

  # Validate the specified LUKS device
  if ! cryptsetup isLuks "$luks_device" >>"$LOG_FILE" 2>&1; then
    error "Device '$luks_device' is not a LUKS partition or does not exist. Please verify."
  fi

  # Configure dracut
  configure_dracut

  info "Enrolling TPM2 with systemd-cryptenroll for '$luks_device' using PCRs: $tpm_pcrs"
  # --wipe-slot tpm2: Ensures any existing TPM2 slot is cleared before adding a new one.
  # --tpm2-device auto: Automatically detects the TPM2 device.
  # --tpm2-pcrs: Specifies the Platform Configuration Registers to bind the key to.
  systemd-cryptenroll --wipe-slot tpm2 --tpm2-device auto --tpm2-pcrs "$tpm_pcrs" "$luks_device" >>"$LOG_FILE" 2>&1
  if [[ $? -ne 0 ]]; then
    error "Failed to enroll TPM2 with systemd-cryptenroll. Check '$LOG_FILE' for details."
  fi
  success "TPM2 successfully enrolled with systemd-cryptenroll."

  info "Configuring /etc/crypttab for TPM2 unlock."
  local luks_uuid=$(blkid -s UUID -o value "$luks_device")
  local crypttab_entry_name="cryptroot" # Common name, adjust if yours is different
  local crypttab_options="luks,discard,tpm2-device=auto,tpm2-pcrs=$tpm_pcrs"

  # Backup /etc/crypttab before modification
  if [[ -f /etc/crypttab ]]; then
    info "Backing up /etc/crypttab to /etc/crypttab.bak"
    cp /etc/crypttab /etc/crypttab.bak
  else
    warn "/etc/crypttab does not exist. It will be created."
  fi

  # Check if an entry for the LUKS device (by UUID) already exists in crypttab
  if grep -q "UUID=$luks_uuid" /etc/crypttab; then
    info "Entry for '$luks_device' (UUID=$luks_uuid) found in /etc/crypttab. Modifying it."
    # Use sed to replace the options for the line containing the UUID
    # This sed command targets lines that contain the UUID and replaces the options part.
    # It assumes the options are the 4th field and beyond.
    sed -i "/UUID=$luks_uuid/ s/\(^[[:space:]]*[^[:space:]]\+[[:space:]]\+UUID=$luks_uuid[[:space:]]\+[^[:space:]]\+[^[:space:]]\+\).*$/\1,$crypttab_options/" /etc/crypttab
    # If the sed command above is too complex or fails, a simpler approach is to remove and re-add:
    # sed -i "/UUID=$luks_uuid/d" /etc/crypttab
    # echo "$crypttab_entry_name UUID=$luks_uuid none $crypttab_options" >> /etc/crypttab
  else
    info "No entry for '$luks_device' (UUID=$luks_uuid) found in /etc/crypttab. Adding a new one."
    # Append a new entry to /etc/crypttab
    echo "$crypttab_entry_name UUID=$luks_uuid none $crypttab_options" >>/etc/crypttab
  fi

  success "TPM2 configuration completed. You should now be able to unlock your LUKS partition with TPM2 on boot."
  warn "Please reboot your system to test the configuration."
}

# --- Main Script Execution Flow ---
# Checks for TPM device and prompts the user for configuration.
if tpm_device_exists; then
  info "TPM device detected on your system."
  while true; do
    read -r -p "Do you want to configure the TPM chip to unlock a LUKS partition? (Y/N): " answer
    case $answer in
    [Yy]*)
      configure_tpm_module
      break
      ;;
    [Nn]*)
      info "TPM configuration skipped."
      break
      ;;
    *)
      warn "Invalid choice. Please answer Y or N."
      ;;
    esac
  done
else
  warn "TPM device not found on this system. TPM configuration cannot proceed."
fi
