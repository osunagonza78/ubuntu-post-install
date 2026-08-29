#!/bin/bash

###############################################################################
# Virtualization Stack Installation Script for Ubuntu
###############################################################################
# This script installs and configures the complete virtualization stack
# including KVM/QEMU hypervisor, libvirt daemon, and virtualization tools.
#
# Author: Gilberto Osuna Gonzalez
# Version: 1.0
###############################################################################

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../config.env"

###############################################################################
# Functions
###############################################################################

# Install KVM/QEMU packages and configure libvirtd.
# Also adds the current user to the kvm and libvirt groups.
setup_virtualization_stack() {
  log_info "Installing KVM/QEMU virtualization packages..."

  if ! sudo apt-get install -y "${VIRT_PACKAGES[@]}"; then
    log_error "Failed to install virtualization packages"
    return 1
  fi

  log_info "Starting libvirt daemon service..."
  if ! sudo systemctl start libvirtd; then
    log_error "Failed to start libvirtd service"
    return 1
  fi

  log_info "Enabling libvirt service to start on boot..."
  if ! sudo systemctl enable libvirtd --now; then
    log_error "Failed to enable libvirtd service"
    return 1
  fi

  log_info "Adding user '${USER}' to kvm and libvirt groups..."
  sudo usermod -aG kvm "$USER"
  sudo usermod -aG libvirt "$USER"

  log_success "Virtualization stack is now ready for use!"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log_info "Starting virtualization stack installation..."
    log_info "This will install KVM/QEMU hypervisor and configure libvirt services."

    setup_virtualization_stack

    log_success "Virtualization stack installation completed successfully!"
    log_info "You can now create and manage virtual machines using virt-manager or virsh."
    log_info "Note: log out and back in for group membership changes to take effect."
}

main "$@"
