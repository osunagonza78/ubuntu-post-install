#!/bin/bash

###############################################################################
# Package Utilities Library for Ubuntu
###############################################################################
# This library provides reusable functions for package management
#
# Author: Gilberto Osuna Gonzalez
# Version: 1.0
###############################################################################

# Source logging library
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "${SCRIPT_DIR}/logging.sh"

###############################################################################
# Functions
###############################################################################

# Check if a program is installed; install via apt if missing.
#
# @param program The name of the program to check/install
check_program_installed() {
  local program=$1
  if ! command -v "$program" &> /dev/null; then
    log_error "The $program program is not installed."
    log_info "Installing $program..."
    sudo apt-get install -y "$program" || { log_error "Failed to install $program."; exit 1; }
  else
    log_info "The $program program is already installed."
  fi
}

# Install packages from the provided array, skipping already-installed ones.
#
# @param packages_array Array of package names to install
install_packages() {
  local packages_array=("$@")
  if [ ${#packages_array[@]} -eq 0 ]; then
    log_error "No packages provided to install_packages function"
    return 1
  fi

  log_info "Checking ${#packages_array[@]} packages..."
  local to_install=()

  for program in "${packages_array[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$program" 2>/dev/null | grep -q "install ok installed"; then
      to_install+=("$program")
    else
      log_info "Already installed: $program"
    fi
  done

  if [ ${#to_install[@]} -eq 0 ]; then
    log_success "All packages are already installed"
    return 0
  fi

  log_info "Installing ${#to_install[@]} packages: ${to_install[*]}"
  if ! sudo apt-get install -y "${to_install[@]}"; then
    log_error "Package installation failed"
    return 1
  fi

  log_success "All packages installed successfully"
}
