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
# Using 256-color palette for a professional look
ACCENT='\033[38;5;75m'   # Soft Blue/Cyan
PRIMARY='\033[38;5;111m' # Light Blue
SUCCESS='\033[38;5;82m'  # Soft Green
WARNING='\033[38;5;220m' # Soft Yellow
DANGER='\033[38;5;196m'  # Soft Red
INFO='\033[38;5;153m'    # Pale Cyan
DIM='\033[38;5;242m'     # Gray
NO_COLOR='\033[0m'
BOLD='\033[1m'

# Log file path
LOG_FILE="$HOME/ubuntu-post-install.log"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Center text within a given width
# Usage: center_text "Text to center" width
center_text() {
    local text="$1"
    local width="$2"
    local text_len=${#text}
    local padding=$(( width - text_len ))
    local left_pad=$(( padding / 2 ))
    local right_pad=$(( padding - left_pad ))

    printf "%${left_pad}s%s%${right_pad}s" "" "$text" ""
}

# Helper to write to both stdout and log file
_log_write() {
    local level="$1"
    local msg="$2"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    # Print to console
    echo -e "${level} - $msg"

    # Append to log file (stripped of ANSI colors for the log)
    echo "[$timestamp] $msg" >> "$LOG_FILE"
}

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# Usage: log_info "Your message here"
log_info() {
    _log_write "${INFO}[INFO]${NO_COLOR}" "$1"
}

# Usage: log_warning "Your warning message here"
log_warning() {
    _log_write "${WARNING}[WARNING]${NO_COLOR}" "$1"
}

# Usage: log_error "Your error message here"
log_error() {
    _log_write "${DANGER}[ERROR]${NO_COLOR}" "$1"
}

# Usage: log_success "Your success message here"
log_success() {
    _log_write "${SUCCESS}[SUCCESS]${NO_COLOR}" "$1"
}

# Usage: log_debug "Your debug message here"
log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        _log_write "${PRIMARY}[DEBUG]${NO_COLOR}" "$1"
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
    echo -e "${PRIMARY}──────────────────────────────────────────────────────────────────────────${NO_COLOR}"
}

# Usage: print_section_header "Section Title"
print_section_header() {
    echo
    print_separator
    echo -e "${BOLD}${PRIMARY}$1${NC}"
    print_separator
    echo
}

# Usage: print_step_header "Step Description"
print_step_header() {
    echo -e "${ACCENT}❯ $1${NO_COLOR}"
}
