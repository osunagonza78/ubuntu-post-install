#!/bin/bash

# =============================================================================
# LOGGING LIBRARY
# =============================================================================
# This library provides standardized logging functions for all scripts
# in the Ubuntu post-install collection.
#
# Usage: Source this library in your script and use the logging functions:
#   source "$(dirname "$0")/../lib/logging.sh"
#
# Author: Gilberto Osuna Gonzalez
# Version: 1.0
# =============================================================================

# Color codes for output formatting
RED='\e[1;91m'
GREEN='\e[1;92m'
BLUE='\e[1;94m'
ORANGE='\e[1;93m'
YELLOW='\e[1;33m'
NO_COLOR='\e[0m'

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Usage: log_info "Your message here"
log_info() {
    echo -e "${GREEN}[INFO]${NO_COLOR} - $1"
}

# Usage: log_warning "Your warning message here"
log_warning() {
    echo -e "${YELLOW}[WARNING]${NO_COLOR} - $1"
}

# Usage: log_error "Your error message here"
log_error() {
    echo -e "${RED}[ERROR]${NO_COLOR} - $1"
}

# Usage: log_success "Your success message here"
log_success() {
    echo -e "${GREEN}[SUCCESS]${NO_COLOR} - $1"
}

# Usage: log_debug "Your debug message here"
log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        echo -e "${BLUE}[DEBUG]${NO_COLOR} - $1"
    fi
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Usage: check_command_status "Description of command"
check_command_status() {
    if [ $? -eq 0 ]; then
        log_info "$1 completed successfully"
        return 0
    else
        log_error "$1 failed"
        return 1
    fi
}

# Usage: print_separator
print_separator() {
    echo -e "${BLUE}============================================================================${NO_COLOR}"
}

# Usage: print_section_header "Section Title"
print_section_header() {
    echo
    print_separator
    echo -e "${BLUE}$1${NO_COLOR}"
    print_separator
    echo
}

# Usage: print_step_header "Step Description"
print_step_header() {
    echo -e "${ORANGE}▶ $1${NO_COLOR}"
}
