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

# Global variable to cache the chosen package manager
PKG_MANAGER=""

# Determine the best available package manager (prefer nala)
# Usage: initialize_pkg_manager
initialize_pkg_manager() {
    if [[ -n "$PKG_MANAGER" ]]; then
        return 0
    fi

    if command -v nala &>/dev/null; then
        PKG_MANAGER="nala"
        log_info "Using nala as the package manager."
    else
        log_info "nala not found. Attempting to install nala..."
        if sudo apt-get update -y &>/dev/null && sudo apt-get install -y nala &>/dev/null; then
            PKG_MANAGER="nala"
            log_info "nala installed successfully. Using nala as the package manager."
        else
            PKG_MANAGER="apt-get"
            log_warning "Could not install nala. Falling back to apt-get."
        fi
    fi
}

# Generic wrapper for package installation
# Usage: pkg_install <package1> <package2> ...
pkg_install() {
    initialize_pkg_manager
    if [[ "$PKG_MANAGER" == "nala" ]]; then
        sudo nala install -y "$@"
    else
        sudo apt-get install -y "$@"
    fi
}

# Generic wrapper for system update
# Usage: pkg_update
pkg_update() {
    initialize_pkg_manager
    if [[ "$PKG_MANAGER" == "nala" ]]; then
        sudo nala update
    else
        sudo apt-get update
    fi
}

# Generic wrapper for system upgrade
# Usage: pkg_upgrade <full|dist-upgrade|upgrade>
pkg_upgrade() {
    initialize_pkg_manager
    local type="${1:-upgrade}"
    if [[ "$PKG_MANAGER" == "nala" ]]; then
        # nala upgrade handles full-upgrade equivalents generally
        sudo nala upgrade -y
    else
        sudo apt-get "$type" -y
    fi
}

# Generic wrapper for cleaning up packages
# Usage: pkg_clean <autoremove|autoclean>
pkg_clean() {
    initialize_pkg_manager
    local action="$1"
    if [[ "$PKG_MANAGER" == "nala" ]]; then
        # nala doesn't have direct autoremove in the same way as apt-get
        # we fallback to apt for cleaning tasks to be safe
        sudo apt-get "$action" -y
    else
        sudo apt-get "$action" -y
    fi
}

###############################################################################
# Functions
###############################################################################

# Check if a program is installed; install via pkg_install if missing.
#
# @param program The name of the program to check/install
check_program_installed() {
  local program=$1
  if ! command -v "$program" &> /dev/null; then
    log_error "The $program program is not installed."
    log_info "Installing $program..."
    pkg_install "$program" || { log_error "Failed to install $program."; exit 1; }
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
  if ! pkg_install "${to_install[@]}"; then
    log_error "Package installation failed"
    return 1
  fi

  log_success "All packages installed successfully"
}
