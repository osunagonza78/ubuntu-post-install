#!/bin/bash

# =============================================================================
# OUTPUT PANE HELPER
# =============================================================================
# Drives the persistent right-side tmux output pane used by run.sh.
#
# Subcommands:
#   idle                          Show the idle screen and sleep until killed.
#   run <script> <title> <signal> Run <script>, frame it with header/footer,
#                                 then signal the menu pane and return to idle.
# =============================================================================

set -u

# --- Color Palette ---
ACCENT='\033[38;5;75m'   # Soft Blue/Cyan
PRIMARY='\033[38;5;111m' # Light Blue
SUCCESS='\033[38;5;82m'  # Soft Green
WARNING='\033[38;5;220m' # Soft Yellow
INFO='\033[38;5;153m'    # Pale Cyan
DIM='\033[38;5;242m'     # Gray
BOLD='\033[1m'
NC='\033[0m'

show_idle() {
    clear
    local title="Ubuntu Post-Install — Output"
    local width=58

    echo
    echo -e "  ${ACCENT}┌──────────────────────────────────────────────────────┐${NC}"
    echo -e "  ${ACCENT}│${NC}$(center_text "$title" $width)${ACCENT}│${NC}"
    echo -e "  ${ACCENT}│${NC}"
    echo -e "  ${ACCENT}│${NC}    ${DIM}Pick an option from the menu on the left.${NC}        ${ACCENT}│${NC}"
    echo -e "  ${ACCENT}│${NC}    ${DIM}Its output will stream here.${NC}                      ${ACCENT}│${NC}"
    echo -e "  ${ACCENT}│${NC}"
    echo -e "  ${ACCENT}└──────────────────────────────────────────────────────┘${NC}"
    echo
    trap 'exit 0' TERM INT
    while :; do sleep 3600; done
}

run_target() {
    local target="$1" title="$2" signal="$3"

    clear
    local width=58
    echo -e "${ACCENT}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${ACCENT}│${NC}${BOLD}${ACCENT}$(center_text "$title" $width)${NC}${ACCENT}│${NC}"
    echo -e "${ACCENT}└──────────────────────────────────────────────────────────┘${NC}"
    echo

    bash "$target"
    local rc=$?

    echo
    echo -e "${PRIMARY}──────────────────────────────────────────────────────────${NC}"
    if [[ $rc -eq 0 ]]; then
        echo -e "${SUCCESS}✓ Completed successfully!${NC}"
    else
        echo -e "${WARNING}⚠ Completed with exit code: ${rc}${NC}"
    fi
    echo -e "${INFO}Press Enter to return to the menu...${NC}"
    read -r _

    # Unblock the menu pane, then idle so this pane stays alive for the next run.
    tmux wait-for -S "$signal" 2>/dev/null
    show_idle
}

case "${1:-idle}" in
    idle) show_idle ;;
    run)  run_target "$2" "$3" "$4" ;;
    *)    echo "Unknown subcommand: $1" >&2; exit 1 ;;
esac
