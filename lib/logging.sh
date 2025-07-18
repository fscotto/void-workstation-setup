#!/usr/bin/env bash

#
# logging.sh - Simple logging functions for bash scripts
# Usage: source this script, then call info/warn/error/success for formatted logs
#

LOG_FILE="${LOG_FILE:-install.log}"

# Print informational message with timestamp
info() {
  local msg="$*"
  echo -e "[\033[1;34mINFO\033[0m] $(date +'%Y-%m-%d %H:%M:%S') - $msg"
  echo "[INFO] $(date +'%Y-%m-%d %H:%M:%S') - $msg" >>"$LOG_FILE"
}

# Print warning message with timestamp
warn() {
  local msg="$*"
  echo -e "[\033[1;33mWARN\033[0m] $(date +'%Y-%m-%d %H:%M:%S') - $msg"
  echo "[WARN] $(date +'%Y-%m-%d %H:%M:%S') - $msg" >>"$LOG_FILE"
}

# Print error message with timestamp
error() {
  local msg="$*"
  echo -e "[\033[1;31mERROR\033[0m] $(date +'%Y-%m-%d %H:%M:%S') - $msg" >&2
  echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S') - $msg" >>"$LOG_FILE"
}

# Print success message with timestamp
success() {
  local msg="$*"
  echo -e "[\033[1;32mSUCCESS\033[0m] $(date +'%Y-%m-%d %H:%M:%S') - $msg"
  echo "[SUCCESS] $(date +'%Y-%m-%d %H:%M:%S') - $msg" >>"$LOG_FILE"
}
