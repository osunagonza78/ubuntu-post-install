#!/bin/bash

###############################################################################
# System Configuration Script for Ubuntu
###############################################################################
# This script configures system settings, enables extra repositories, and
# performs system optimizations for Ubuntu Linux.
#
# Author: Gilberto Osuna Gonzalez
# Version: 1.0
###############################################################################

# Source logging library
SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../lib/package_utils.sh"

###############################################################################
# Functions
###############################################################################

# Perform a full system upgrade and cleanup.
perform_updates() {
    log_info "Performing system update and upgrade..."
    sudo apt-get update
    check_command_status "apt update" || return 1

    sudo apt-get full-upgrade -y
    check_command_status "apt full-upgrade" || return 1

    sudo apt-get autoremove -y
    sudo apt-get autoclean -y

    log_success "System update completed"
}

# Disable NetworkManager-wait-online to speed up boot time.
perform_optimizations() {
    log_info "Performing boot optimizations..."
    sudo systemctl disable NetworkManager-wait-online.service 2>/dev/null || true
    log_success "Boot optimizations applied"
}

###############################################################################
# Main script
###############################################################################

check_program_installed wget

perform_optimizations

perform_updates

log_info "Sleeping 5 seconds before system restart..."
sleep 5

read -p "System configuration complete. A reboot is required. Reboot now? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Rebooting system..."
    reboot
else
    log_info "Reboot deferred. Please remember to reboot your system manually to apply all changes."
fi
