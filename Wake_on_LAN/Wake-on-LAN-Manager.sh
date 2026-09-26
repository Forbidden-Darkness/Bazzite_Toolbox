#!/usr/bin/env bash
clear

# ==============================================================================
# PREMIUM SYSTEM GRAPHICAL TERMINAL PROPERTIES & STYLING LOGIC
# ==============================================================================
RED='\033[0;31m'    local B_RED='\033[1;31m'     local GREEN='\033[0;32m'
YELLOW='\033[1;33m' local B_BLUE='\033[1;34m'    local CYAN='\033[0;36m'
BIYellow='\033[1;93m' local BICyan='\033[1;96m'  local BIWhite='\033[1;97m'
NC='\033[0m'        local RESET='\033[0m'        local BOLD='\033[1m'
DIM='\033[38;2;110;110;110m'

# Verify high-privilege administrative boundary permissions
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ ERROR: High-privilege access execution layer constraint violation."
    echo -e "          Please invoke this network manager via: sudo bash $0${NC}"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SCRIPT_PATH=$(realpath "$0")

# 🧬 AUDIO CONFIRMATION CORE: Routes signals cleanly down Pipewire session buses [1.14]
play_success_chime() {
    echo -ne '\e[?5h'; sleep 0.1; echo -ne '\e[?5l'
    local real_uid; real_uid=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")
    if [[ -f "/usr/share/sounds/oxygen/stereo/outcome-success.ogg" ]] && command -v pw-play &>/dev/null; then
        sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$real_uid" PIPEWIRE_RUNTIME_DIR="/run/user/$real_uid" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$real_uid/bus" pw-play /usr/share/sounds/oxygen/stereo/outcome-success.ogg &>/dev/null || true
    fi
}

print_success() { echo -e "\n  ${BOLD}${GREEN}✔  $1${RESET}\n"; }
print_error() { echo -e "\n  ${BOLD}${RED}✘  $1${RESET}\n"; }

# ==============================================================================
# INTERACTIVE DESKTOP SHORTCUT DEPLOYER INFRASTRUCTURE
# ==============================================================================
ask_desktop_shortcut() {
    local desktop_dir
    desktop_dir="$(sudo -u "$REAL_USER" xdg-user-dir DESKTOP 2>/dev/null || echo "")"
    [[ -n "$desktop_dir" ]] || desktop_dir="$REAL_HOME/Desktop"
    [[ -d "$desktop_dir" ]] || mkdir -p "$desktop_dir" 2>/dev/null || return 0

    local shortcut="$desktop_dir/Start Wake on LAN Manager.desktop"
    [[ -f "$shortcut" ]] && return 0

    echo -e "  ${CYAN}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║                     ⚙️ DESKTOP ACCELERATOR LAUNCHER SHORTCUT CONFIGURATOR                    ║${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "    ${BIYellow}Would you like to deploy an unprivileged application desktop shortcut launcher?${NC}"
    echo -e "  ${DIM}  ───────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "     ${CYAN}1)${NC} Yes, build a native desktop launcher file   ${DIM}(Automates console escalation path)${NC}"
    echo ""
    echo -e "     ${CYAN}2)${NC} No, skip shortcut configuration layout"
    echo ""
    echo -e "     ${RED}[Enter]${NC} Skip accelerator deployment and pass straight to active dashboard"
    echo -e "  ${DIM}  ───────────────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""

    local shortcut_choice; read -r -p "   Select configuration target index option [1-2]: " shortcut_choice
    case $shortcut_choice in
        1)
            sudo -u "$REAL_USER" tee "$shortcut" > /dev/null <<SHORTCUT_EOF
[Desktop Entry]
Type=Application
Name=Wake on LAN Manager
Comment=Manage Remote Wake-on-LAN Parameters
Exec=konsole -e sudo bash "$SCRIPT_PATH"
Icon=utilities-terminal
Terminal=false
Categories=System;
SHORTCUT_EOF
            chmod +x "$shortcut"
            chown "$REAL_USER":"$REAL_USER" "$shortcut" 2>/dev/null || true
            sudo -u "$REAL_USER" gio set "$shortcut" metadata::trusted true >/dev/null 2>&1 || true
            print_success "Wake on LAN Manager user interface launcher deployed smoothly!"
            sleep 1.2
            ;;
        *) sleep 0.2 ;;
    esac
}

ask_desktop_shortcut
clear
# ==============================================================================
# MAIN DEPLOYMENT ACTIONS INTERFACE (93-CHARACTER WIDE GRID)
# ==============================================================================
echo -e "  ${CYAN}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}║                     📡 WAKE-ON-LAN HARDWARE REGISTER OVERRIDE MANAGER                       ║${NC}"
echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "    ${BOLD}${YELLOW}Deployment Actions & Core Firmware Settings${NC}"
echo -e "  ${DIM}  ───────────────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "     ${CYAN}[1]${NC} Enable WoL Magic Packet Receiver   ${DIM}(Recommended link mode for remote power plane on)${RESET}"
echo ""
echo -e "     ${CYAN}[2]${NC} Disable WoL Network Requests       ${DIM}(Forced clamp to drop standby power rail drain)${RESET}"
echo ""
echo -e "     ${RED}[Enter]${NC} Abort Adapter Tweaks and Return Back to Master Dashboard"
echo -e "  ${DIM}  ───────────────────────────────────────────────────────────────────────────────────────────${NC}"
echo ""

local ACTION_CHOICE; read -r -p "   Select target network power plane option [1-2]: " ACTION_CHOICE
local WOL_SETTING="" local ACTION_TEXT=""

if [ "$ACTION_CHOICE" = "1" ]; then
    WOL_SETTING="magic"; ACTION_TEXT="Enabling"
elif [ "$ACTION_CHOICE" = "2" ]; then
    WOL_SETTING="ignore"; ACTION_TEXT="Disabling"
elif [ -z "$ACTION_CHOICE" ]; then
    echo -e "\n  ${YELLOW}[-] Operation aborted. Returning safely to master toolkit interface...${NC}"
    sleep 1.0; exit 0
else
    print_error "Invalid operational constraint array choice selection. Aborting execution thread."
    exit 1
fi

# ==============================================================================
# DEVICE CARD FILTER & DISCOVERY MATRIX
# ==============================================================================
CONNECTIONS=()
while read -r conn_name; do
    [ -z "$conn_name" ] && continue
    raw_type=$(nmcli -g connection.type connection show "$conn_name" 2>/dev/null)
    if [[ "$raw_type" == *"ethernet"* || "$raw_type" == *"wireless"* ]]; then
        CONNECTIONS+=("$conn_name")
    fi
done < <(nmcli -g NAME connection show)

if [ ${#CONNECTIONS[@]} -eq 0 ]; then
    print_error "No active NetworkManager Network profiles discovered inside host configuration matrices."
    exit 1
fi

echo -e "\n    ${BOLD}${YELLOW}Discovered Active Host Network Interface Configurations:${RESET}"
echo -e "  ${DIM}  ───────────────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "     ${CYAN}[0]${NC} CONFIGURE ALL DISCOVERED SYSTEM INTERFACES FLAT"
for i in "${!CONNECTIONS[@]}"; do
    printf "     ${CYAN}[%d]${NC} %s\n" "$((i+1))" "${CONNECTIONS[$i]}"
done
echo -e "  ${DIM}  ───────────────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "  ${DIM}  * Enter multiple target indexes separated flatly by spaces (e.g., '1 2') or select '0' *${RESET}"
echo ""

read -r -p "   Selection Bus Matrix Array: " -a USER_SELECTIONS
TARGET_CONNECTIONS=()
if [[ " ${USER_SELECTIONS[*]} " =~ " 0 " ]]; then
    TARGET_CONNECTIONS=("${CONNECTIONS[@]}")
else
    for sel in "${USER_SELECTIONS[@]}"; do
        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -le "${#CONNECTIONS[@]}" ] && [ "$sel" -gt 0 ]; then
            TARGET_CONNECTIONS+=("${CONNECTIONS[$((sel-1))]}")
        else
            echo -e "  ${RED}[⚠] Warning: Out of bounds tracking logical link node index selection '$sel' skipped.${NC}"
        fi
    done
fi

if [ ${#TARGET_CONNECTIONS[@]} -eq 0 ]; then
    print_error "No valid network hardware adapter interfaces assigned to the array pipeline. Exiting."
    exit 1
fi

# ==============================================================================
# PARAMETER MODIFICATION & COMMIT TUNING PIPELINE
# ==============================================================================
echo -e "\n  ${GREEN}[+] Synchronizing interface bus properties across selected adapters...${NC}"
echo -e "  ${DIM}  ───────────────────────────────────────────────────────────────────────────────────────────${NC}"

for CONN in "${TARGET_CONNECTIONS[@]}"; do
    [ -z "$CONN" ] && continue
    echo -e "  ⚡ Target Node: ${BIWhite}'$CONN'${NC}"

    CONN_TYPE=$(nmcli -g connection.type connection show "$CONN" 2>/dev/null)
    if [[ "$CONN_TYPE" == *"ethernet"* ]]; then
        PROP_PREFIX="802-3-ethernet"
    elif [[ "$CONN_TYPE" == *"wireless"* ]]; then
        PROP_PREFIX="802-11-wireless"
    else
        echo -e "  ${RED}❌ Skipping un-mappable interface adapter profile: $CONN_TYPE${NC}"
        echo -e "  ${DIM}  ───────────────────────────────────────────────────────────────────────────────────────────${NC}"
        continue
    fi

    echo -e "     ↳ ${ACTION_TEXT} hardware magic packet wake registers..."
    nmcli c modify "$CONN" "${PROP_PREFIX}.wake-on-lan" "$WOL_SETTING"

    echo -e "     ↳ Active Runtime Configuration Verification State:"
    nmcli c show "$CONN" | grep -i "wake-on-lan" | sed 's/^/       /'
    echo -e "  ${DIM}  ───────────────────────────────────────────────────────────────────────────────────────────${NC}"
done
# ==============================================================================
# POST-CONFIGURATION DAEMON RESTART INTERFACE
# ==============================================================================
# 🚀 CHIME INITIALIZATION: Fire audio notification loop exactly upon task success [1.14]
play_success_chime

print_success "Network hardware silicon adapter tuning parameter injection cycle complete!"
echo -e "    ${BOLD}${YELLOW}What post-processing state transition would you like to execute?${NC}"
echo -e "  ${DIM}  ───────────────────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "     ${CYAN}[1]${NC} Hot-Reload NetworkManager daemon sub-systems  ${DIM}(Flushes connection tables instantly)${RESET}"
echo ""
echo -e "     ${CYAN}[2]${RESET} Execute a clean full system hardware reboot"
echo ""
echo -e "     ${RED}[3]${RESET} Exit installer engine immediately          ${DIM}(Changes lock and load on next boot)${RESET}"
echo -e "  ${DIM}  ───────────────────────────────────────────────────────────────────────────────────────────${NC}"
echo ""

local POST_CHOICE; read -r -p "   Select hardware post-processing action target [1-3]: " POST_CHOICE
case "$POST_CHOICE" in
    1)
        echo -e "\n  ${GREEN}[+] Flushing NetworkManager routing profiles into operating system memory space...${NC}"
        systemctl restart NetworkManager
        print_success "Network stack parameters successfully cleared and initialized!"
        sleep 1.2; exit 0 ;;
    2)
        echo -e "\n  ${GREEN}[+] Commencing hard kernel synchronization pass... Rebooting device now...${NC}"
        sleep 1.5; reboot ;;
    *)
        echo -e "\n  ${YELLOW}[-] Terminating session pipeline. Modifications locked into static system storage profiles.${NC}"
        sleep 1.2; exit 0 ;;
esac
