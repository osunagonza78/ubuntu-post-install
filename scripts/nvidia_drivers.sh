#!/bin/bash

# =============================================================================
# NVIDIA Drivers and Hardware Acceleration Setup Script for Ubuntu
# =============================================================================
# This script installs NVIDIA drivers and configures hardware acceleration
# for video playback and GPU computing on Ubuntu Linux.
#
# Ubuntu uses the ubuntu-drivers utility for automatic driver detection and
# installation, which is the recommended approach for most setups.
#
# Author: Gilberto Osuna Gonzalez
# Version: 1.0
# =============================================================================

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../config.env"

###############################################################################
# Functions
###############################################################################

# Install VA-API/VDPAU utilities and multimedia codec packages.
hardware_acceleration_setup() {
    log_info "Setting up hardware acceleration for video playback..."

    if ! sudo apt-get install -y "${ACCEL_PACKAGES[@]}"; then
        log_error "Failed to install hardware acceleration packages"
        return 1
    fi

    log_success "Hardware acceleration setup completed"
    return 0
}

# Install NVIDIA proprietary drivers using ubuntu-drivers.
# ubuntu-drivers detects the GPU and installs the recommended driver version.
install_nvidia_drivers() {
    log_info "Installing NVIDIA proprietary drivers via ubuntu-drivers..."

    if ! sudo apt-get install -y ubuntu-drivers-common; then
        log_error "Failed to install ubuntu-drivers-common"
        return 1
    fi

    log_info "Detecting GPU and selecting recommended NVIDIA driver..."
    sudo ubuntu-drivers devices

    # Try autoinstall first
    if sudo ubuntu-drivers autoinstall; then
        log_success "NVIDIA drivers installed via ubuntu-drivers autoinstall"
        return 0
    fi

    log_warning "ubuntu-drivers autoinstall failed or command not found. Attempting manual installation of recommended driver..."

    # Fallback: Parse the recommended driver from 'ubuntu-drivers devices'
    local recommended_driver
    recommended_driver=$(ubuntu-drivers devices | grep 'recommended' | awk '{print $3}')

    if [[ -n "$recommended_driver" ]]; then
        log_info "Recommended driver identified: $recommended_driver"
        if sudo apt-get install -y "$recommended_driver"; then
            log_success "NVIDIA drivers installed successfully via apt: $recommended_driver"
            return 0
        else
            log_error "Failed to install recommended driver: $recommended_driver"
            return 1
        fi
    else
        log_error "Could not identify a recommended NVIDIA driver."
        log_warning "You can install a specific driver version manually, e.g.:"
        log_warning "  sudo apt-get install -y nvidia-driver-550"
        return 1
    fi
}

# Optionally install the NVIDIA CUDA toolkit for GPU compute workloads.
install_cuda_support() {
    log_info "Installing NVIDIA CUDA toolkit..."

    if ! sudo apt-get install -y nvidia-cuda-toolkit; then
        log_warning "Failed to install CUDA toolkit — continuing without it"
        return 1
    fi

    log_success "CUDA toolkit installed"
    return 0
}

# Check whether the NVIDIA kernel module appears loaded (it won't be until reboot).
verify_nvidia_installation() {
    log_info "Verifying NVIDIA kernel module installation..."

    if modinfo -F version nvidia >/dev/null 2>&1; then
        local nvidia_version
        nvidia_version=$(modinfo -F version nvidia 2>/dev/null)
        log_info "NVIDIA kernel module is loaded (version: ${nvidia_version})"
        return 0
    else
        log_warning "NVIDIA kernel module is not yet loaded — this is normal immediately after installation."
        log_warning "The module will be active after reboot."
        return 1
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log_info "Starting NVIDIA drivers and hardware acceleration setup..."

    hardware_acceleration_setup
    local hw_accel_status=$?

    install_nvidia_drivers
    local nvidia_status=$?

    install_cuda_support

    verify_nvidia_installation

    echo
    print_section_header "POST-INSTALLATION INSTRUCTIONS"

    echo -e "${BLUE}1. Verify recommended driver selected:${NO_COLOR}"
    echo -e "   ${YELLOW}ubuntu-drivers devices${NO_COLOR}"
    echo
    echo -e "${BLUE}2. Check NVIDIA driver status after reboot:${NO_COLOR}"
    echo -e "   ${YELLOW}nvidia-smi${NO_COLOR}"
    echo
    echo -e "${BLUE}3. Reboot the system:${NO_COLOR}"
    echo -e "   ${YELLOW}sudo reboot${NO_COLOR}"
    echo -e "   ${ORANGE}Note: the driver will be active only after reboot.${NO_COLOR}"
    echo
    echo -e "${BLUE}4. After reboot, verify installation:${NO_COLOR}"
    echo -e "   ${YELLOW}nvidia-settings${NO_COLOR}"
    echo -e "   ${YELLOW}glxinfo | grep \"OpenGL renderer\"${NO_COLOR}"
    echo

    if [[ $hw_accel_status -eq 0 && $nvidia_status -eq 0 ]]; then
        log_info "Setup completed successfully! Please follow the post-installation instructions above."
        exit 0
    else
        log_error "Setup encountered errors. Please check the messages above and resolve any issues."
        exit 1
    fi
}

main "$@"
