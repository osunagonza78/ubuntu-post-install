#!/bin/bash

# =============================================================================
# Ubuntu Post-Installation Tool
# =============================================================================
# A comprehensive post-installation configuration tool for Ubuntu Linux that
# automates system setup, package installation, driver configuration, and
# security settings through an interactive menu interface.
#
# Copyright (C) 2025 Gilberto Osuna Gonzalez
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# Author: Gilberto Osuna Gonzalez
# Version: 1.0
# License: GPL v3.0
# Repository: https://github.com/gosuna78/ubuntu-post-install
# =============================================================================

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/"
source "${SCRIPT_DIR}lib/logging.sh"

# Ensure the user has sudo access before starting
check_sudo_access() {
    if ! sudo -v &>/dev/null; then
        echo -e "\n${DANGER}✘ Error:${NC} This tool requires sudo privileges."
        echo -e "${INFO}Please run it with sudo or ensure your user is in the sudoers group.${NC}"
        echo -e "${INFO}Press Enter to exit...${NC}"
        read
        exit 1
    fi
}

# Run the pre-check
check_sudo_access


# --- Auto-launch in tmux for split-pane view ---
# We run on a dedicated tmux socket so our keybindings, styling, and
# kill-server-on-exit don't leak into the user's main tmux config.
UPI_TMUX_SOCKET="upi-postinstall"
if command -v tmux &>/dev/null && [[ -z "$TMUX" ]]; then
    exec tmux -L "$UPI_TMUX_SOCKET" new-session "bash \"${SCRIPT_DIR}run.sh\""
fi

# --- One-time tmux configuration + pane layout ---
# Configure ergonomic bindings/styling on this dedicated server, then spawn the
# persistent right-side output pane.  The pane stays alive for the whole
# session and is reused for every operation so the layout never flashes.
if [[ -n "$TMUX" && -z "$UPI_OUTPUT_PANE" ]]; then
    # Pane navigation: Alt+arrows move focus, mouse clicks focus a pane.
    tmux bind-key -n M-Left  select-pane -L
    tmux bind-key -n M-Right select-pane -R
    tmux set-option -g mouse on
    tmux set-option -g status off
    tmux set-window-option -g pane-border-style        'fg=colour240'
    tmux set-window-option -g pane-active-border-style 'fg=colour39,bold'

    UPI_MENU_PANE=$(tmux display-message -p '#{pane_id}')
    UPI_OUTPUT_PANE=$(tmux split-window -h -l 55% -P -F '#{pane_id}' -d \
        "bash '${SCRIPT_DIR}lib/output_pane.sh' idle")
    export UPI_MENU_PANE UPI_OUTPUT_PANE
fi

# =============================================================================
# FUNCTIONS
# =============================================================================

# Display the application header and title
# Usage: show_header
show_header() {
    clear
    local title="UBUNTU POST-INSTALL TOOL"
    local width=58

    echo -e "${ACCENT}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${ACCENT}│${NC}${BOLD}${ACCENT}$(center_text "$title" $width)${NC}${ACCENT}│${NC}"
    echo -e "${ACCENT}└──────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Paint the menu pane while a script is running in the right pane.
# Usage: show_running_state "Window Title"
show_running_state() {
    local title="$1"
    show_header
    echo -e "  ${ACCENT}❯${NC} ${BOLD}Executing:${NC} ${PRIMARY}${title}${NC}"
    echo ""
    echo -e "  ${DIM}Output is streaming in the right pane.${NC}"
    echo -e "  ${DIM}Press Enter there to return to the menu.${NC}"
    echo ""
    echo -e "${DIM}──────────────────────────────────────────────────────────${NC}"
    echo -e "${INFO}Alt+←/→ switch panes  •  Click a pane to focus it${NC}"
}

# Execute a script in the persistent output pane (tmux) or inline (fallback).
# @param script_name The filename of the script to execute (relative to SCRIPT_DIR)
# @param window_title Human-readable title shown in the output pane header
# Usage: run_script "scripts/script_name.sh" "Display Title"
run_script() {
    local script_name="$1"
    local window_title="$2"
    local full_path="${SCRIPT_DIR}${script_name}"

    if [[ ! -f "$full_path" ]]; then
        echo -e "\n${DANGER}✘ Error:${NC} ${script_name} not found in ${SCRIPT_DIR}"
        echo -e "${INFO}Press Enter to return to menu...${NC}"
        read
        return 1
    fi

    chmod +x "$full_path"

    if [[ -n "$TMUX" && -n "$UPI_OUTPUT_PANE" ]]; then
        local signal="upi_run_$$_${RANDOM}"
        tmux select-pane -t "$UPI_OUTPUT_PANE"
        tmux respawn-pane -k -t "$UPI_OUTPUT_PANE" \
            "bash '${SCRIPT_DIR}lib/output_pane.sh' run '${full_path}' '${window_title}' '${signal}'"
        show_running_state "$window_title"
        tmux wait-for "$signal"
        tmux select-pane -t "${UPI_MENU_PANE:-:.0}"
    else
        # Fallback when tmux is unavailable: run inline.
        clear
        local width=58
        echo -e "${ACCENT}┌──────────────────────────────────────────────────────────┐${NC}"
        echo -e "${ACCENT}│${NC}${BOLD}${ACCENT}$(center_text "$window_title" $width)${NC}${ACCENT}│${NC}"
        echo -e "${ACCENT}└──────────────────────────────────────────────────────────┘${NC}"
        echo ""
        bash "$full_path"
        local exit_code=$?
        echo ""
        echo -e "${PRIMARY}──────────────────────────────────────────────────────────${NC}"
        if [[ $exit_code -eq 0 ]]; then
            echo -e "${SUCCESS}✓ Completed successfully!${NC}"
        else
            echo -e "${WARNING}⚠ Completed with exit code: $exit_code${NC}"
        fi
        echo -e "${INFO}Press Enter to return to menu...${NC}"
        read
    fi
}

# Display the main menu interface with arrow key navigation
# Usage: show_menu selected_index
show_menu() {
    local selected_index="$1"
    show_header

    local -a menu_items=(
        "System Configuration|Optimize APT, enable extra repos, and tune system limits."
        "Packages Installation|Enable Universe/Multiverse, Flatpak, and install essential apps."
        "Development Environment Installation|Install Development Tools."
        "Virtualization Stack|Install KVM/QEMU hypervisor and libvirt services."
        "Nvidia Drivers|Install latest proprietary drivers via ubuntu-drivers."
        "Exit|"
    )

    for i in "${!menu_items[@]}"; do
        local item="${menu_items[$i]}"
        local text="${item%%|*}"
        local desc="${item#*|}"

        if [[ $i -eq $selected_index ]]; then
            echo -e "${ACCENT}  ❯ ${BOLD}${text}${NC}"
            if [[ -n "$desc" ]]; then
                echo -e "    ${DIM}${desc}${NC}"
            fi
        else
            echo -e "${DIM}    ${i})${NC} ${text}"
            if [[ -n "$desc" ]]; then
                echo -e "    ${DIM}${desc}${NC}"
            fi
        fi
        echo ""
    done

    echo -e "${DIM}──────────────────────────────────────────────────────────${NC}"
    echo -e "${INFO}↑↓ navigate  •  Enter select  •  Alt+←/→ switch panes${NC}"
}

# Read single character input for arrow key navigation
# Usage: read_key
read_key() {
    local key
    read -s -n1 key 2>/dev/null >&2

    if [[ $key == $'\x1b' ]]; then
        read -s -n2 -t 0.1 key 2>/dev/null >&2
        case $key in
            '[A') echo "UP" ;;
            '[B') echo "DOWN" ;;
            *) echo "OTHER" ;;
        esac
    elif [[ $key == "" ]]; then
        echo "ENTER"
    else
        echo "$key"
    fi
}

# Main program loop that handles arrow key navigation and script execution
main_loop() {
    local selected=0
    local total_options=6

    while true; do
        show_menu $selected
        local key=$(read_key)

        case $key in
            "UP")
                ((selected--))
                if [[ $selected -lt 0 ]]; then
                    selected=$((total_options - 1))
                fi
                ;;
            "DOWN")
                ((selected++))
                if [[ $selected -ge $total_options ]]; then
                    selected=0
                fi
                ;;
            "ENTER")
                case $selected in
                    0) run_script scripts/system_configuration.sh    "System Configuration" ;;
                    1) run_script scripts/packages_installation.sh   "Packages Installation" ;;
                    2) run_script scripts/development_installation.sh "Development Tools Installation" ;;
                    3) run_script scripts/virtualization_installation.sh "Virtualization Stack Installation" ;;
                    4) run_script scripts/nvidia_drivers.sh          "Nvidia Driver Installation" ;;
                    5)
                        echo -e "\n${DANGER}Exiting. Enjoy your new Ubuntu setup!${NC}"
                        if [[ -n "$TMUX" ]]; then
                            exec tmux kill-server
                        fi
                        exit 0
                        ;;
                esac
                ;;
        esac
    done
}

# Execute the main program loop
main_loop
