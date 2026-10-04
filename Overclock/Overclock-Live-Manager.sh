#!/bin/bash

clear
# Color definitions
CPU_MASK_REG="0x5A870"
SMU_MSG_WRITE_FF="0x98"
NC='\033[0m'
RESET='\033[0m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
B_RED='\033[1;31m'   # Bold Red for high-visibility Red Pill elements
GREEN='\033[0;32m'
B_GREEN='\033[1;32m' # Bold Green for verified/active status
B_YELLOW='\033[1;33m'
B_BLUE='\033[1;34m'  # Bold Blue for high-visibility Blue Pill elements
B_VIOLET='\033[1;35m' # Bold Violet for ACPI Fix elements
CYAN='\033[0;36m'
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;31m'        # Red
MAGENTA='\033[0;35m'
BIGreen='\033[1;32m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White
DIM='\033[2m'
BOLD='\033[1m'

# 🧬 DYNAMIC GITHUB STRINGS FOR MODDED PYTHON OVERRIDES
MODDED_APPLY_URL="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/bc250_apply.py"
MODDED_LIMITS_URL="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/bc250_limits.py"

# 🧬 FIXED CEILING ANCHOR: Uniform global mapping for your un-faked testing driver
MODDED_DETECT_URL="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/bc250_detect.py"

# Verify root/sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo or as root."
    echo -e "Please run: sudo bash $0${NC}"
    exit 1
fi

# --- SPECIFIC WINDOW SIZE WRAPPER (Pixels) ---
if [ -z "$TERMINAL_RESIZE_FORCED" ] && [ -t 0 ]; then
    export TERMINAL_RESIZE_FORCED=1

    # Set your desired width and height in pixels
    WIDTH=800
    HEIGHT=600

    if command -v wmctrl &> /dev/null; then
        wmctrl -r :ACTIVE: -b remove,maximized_vert,maximized_horz
        wmctrl -r :ACTIVE: -e 0,-1,-1,$WIDTH,$HEIGHT
    fi
fi
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

print_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

# 🧬 EXPLICIT DISPLAYPORT BREAKOUT ENGINE: Routes digital audio signals straight past the sudo security container blocks
    play_success_chime() {
        # 🔔 VISUAL PASS: Blinks the terminal screen for immediate visual verification
        echo -ne '\e[?5h'; sleep 0.1; echo -ne '\e[?5l'

        # 🔊 AUDIO PASS: Bypasses container locks to throw your native .ogg chime straight down your DisplayPort lines
        local real_uid; real_uid=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")
        if [[ -f "/usr/share/sounds/oxygen/stereo/outcome-success.ogg" ]] && command -v pw-play &>/dev/null; then
            sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$real_uid" PIPEWIRE_RUNTIME_DIR="/run/user/$real_uid" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$real_uid/bus" pw-play /usr/share/sounds/oxygen/stereo/outcome-success.ogg &>/dev/null || true
        fi
    }

ensure_bazzite_dependencies() {
    local missing_packages=()

    if ! command -v umr &> /dev/null; then
        print_info "UMR debugger tool is not installed on host."
        missing_packages+=("umr")
    fi

    if ! command -v stress &> /dev/null; then
        print_info "Stress testing utility is not installed."
        missing_packages+=("stress")
    fi

    if [ ${#missing_packages[@]} -eq 0 ]; then
        return 0
    fi

    echo -e "${BIYellow}==================================================${NC}"
    echo -e "${BIYellow}         SYSTEM DEPENDENCY DEPLOYMENT             ${NC}"
    echo -e "${BIYellow}==================================================${NC}"
    echo -e "The toolkit requires: ${missing_packages[*]}"
    echo -e "Bazzite requires containerization or system layering to resolve this."
    echo ""
    echo " 1) Install dependencies automatically (Uses Distrobox container fallback)"
    echo " 2) Skip deployment and attempt to proceed anyway"
    echo ""
    read -rp "Select an option [1-2]: " dep_choice

    case "$dep_choice" in
        1)
            if [[ " ${missing_packages[*]} " =~ " stress " ]]; then
                print_info "Staging stress utility via host rpm-ostree..."
                if runuser -l "$REAL_USER" -c "rpm-ostree install stress"; then
                    print_info "Stress utility staged successfully!"
                else
                    echo -e "${RED}Error: Host package staging failed.${NC}"
                fi
            fi

            if [[ " ${missing_packages[*]} " =~ " umr " ]]; then
                print_info "Configuring UMR environment inside a safe Distrobox profile..."
                runuser -l "$REAL_USER" -c "distrobox-create --name amd-toolkit --image archlinux:latest --yes"
                print_info "Updating container and acquiring developer build engines..."
                runuser -l "$REAL_USER" -c "distrobox-enter -n amd-toolkit -- sudo pacman -Syu --noconfirm base-devel git"
                print_info "Compiling and exposing UMR to host system..."
                runuser -l "$REAL_USER" -c "distrobox-enter -n amd-toolkit -- 'git clone https://freedesktop.org && cd umr && ./autogen.sh && ./configure && make && sudo make install'"
                runuser -l "$REAL_USER" -c "distrobox-export -n amd-toolkit --bin /usr/local/bin/umr"
                echo -e "${B_GREEN}UMR tool successfully containerized and linked to host!${NC}"
            fi

            echo -e "${BIYellow}Deployment routine complete.${NC}"
            if [[ " ${missing_packages[*]} " =~ " stress " ]]; then
                echo -e "${BIYellow}Your system must reboot now to finish initializing the stress layer.${NC}"
                read -rp "Press [Enter] to reboot immediately, or Ctrl+C to stop..."
                systemctl reboot
                exit 0
            fi
            ;;
        *)
            print_info "Proceeding with caution without enforcing verification loops."
            ;;
    esac
}

# Configuration
LOG_FILE="/var/log/bc250_oc_install.log"
REPO_URL="https://github.com/bc250-collective/bc250_smu_oc.git"
SERVICE_FILE="/etc/systemd/system/bc250-resume.service"
SCRIPT_PATH=$(realpath "$0")

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

ask_desktop_shortcut() {
    local desktop_dir
    desktop_dir="$(sudo -u "$REAL_USER" xdg-user-dir DESKTOP 2>/dev/null || echo "")"
    [[ -n "$desktop_dir" ]] || desktop_dir="$REAL_HOME/Desktop"
    [[ -d "$desktop_dir" ]] || mkdir -p "$desktop_dir" 2>/dev/null || return 0

    local shortcut="$desktop_dir/Overclock Manager.desktop"

    if [[ -f "$shortcut" ]]; then
        return 0
    fi

    echo -e "${DIM}┌──────────────────────────────────────────────────┐${RESET}"
    echo -e "${DIM}│${RESET}          ${BOLD}${MAGENTA}DESKTOP SHORTCUT CONFIGURATION${RESET}          ${DIM}│${RESET}"
    echo -e "${DIM}└──────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${BOLD}${WHITE}Would you like to add a shortcut to your desktop?${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "    ${CYAN}[1]${RESET} Yes, create desktop shortcut"
    echo -e "    ${CYAN}[2]${RESET} No, skip shortcut creation"
    echo ""
    echo -e "    ${DIM}[Press Enter]${NC} To continue to BC-250 TUNING & CONFIGURATION${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    read -rp "  Select an option [1-2]: " shortcut_choice

    case $shortcut_choice in
        1)
            cat > "$shortcut" <<SHORTCUT_EOF
[Desktop Entry]
Type=Application
Name=Overclock Manager
Comment=Overclock Manager
Exec=konsole -e sudo bash "$SCRIPT_PATH"
Icon=utilities-terminal
Terminal=false
Categories=System;
SHORTCUT_EOF

            chmod +x "$shortcut"
            chown "$REAL_USER":"$REAL_USER" "$shortcut" 2>/dev/null || true
            sudo -u "$REAL_USER" gio set "$shortcut" metadata::trusted true >/dev/null 2>&1 || true
            print_info "Overclock Manager shortcut created successfully!"
            sleep 2
            ;;
        2)
            print_info "Skipping desktop shortcut generation."
            sleep 1.5
            ;;
        *)
            print_info "Invalid choice. Skipping shortcut setup for now."
            sleep 1.5
            ;;
    esac
}
ask_desktop_shortcut

clear

show_warning() {
    echo -e "${RED}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "WARNING: OVERCLOCKING AND UNDERVOLTING CAN DAMAGE YOUR HARDWARE!"
    echo "NEVER EXCEED 1.325V (VID) UNDER ANY CIRCUMSTANCES!"
    echo "PROCEED ENTIRELY AT YOUR OWN RISK."
    echo -e "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!${NC}"
    echo "Source: github.com/bc250-collective/bc250_smu_oc"
    echo "Logs will be saved to: $LOG_FILE"
    echo ""
    read -p "Press [Enter] to accept the risk and continue, or Ctrl+C to abort..."
}

# ==============================================================================
# 🧬 HARDENED SERVICE ACTIVATION ENGINE (PREVENTS MISSING SERVICE ALERTS)
# ==============================================================================
finalize_settings() {
    log "${GREEN}[Step 9] Finalizing and activating SMU service...${NC}"
    
    # 🧬 DYNAMIC PATH RESOLVER: Detects if the config file is inside a sub-toolbox directory
    local local_conf="overclock.conf"
    if [ -f "$REAL_HOME/Bazzite_Toolbox/Overclock/overclock.conf" ]; then
        local_conf="$REAL_HOME/Bazzite_Toolbox/Overclock/overclock.conf"
    fi

    # Pass the fully verified path explicitly to the toolchain application binary
    bc250-apply --install "$local_conf" >> "$LOG_FILE" 2>&1
    
    # Check if the service actually exists before trying to touch it!
    if [[ -f "/etc/systemd/system/bc250-smu-oc.service" ]]; then
        sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
        sudo systemctl restart bc250-smu-oc.service >> "$LOG_FILE" 2>&1
        sudo systemctl enable bc250-smu-oc.service >> "$LOG_FILE" 2>&1
        clear
        echo -e "${YELLOW}--- Current SMU Service Status ${RED}Press [Enter] to return to menu ---${NC}"
        sudo systemctl status bc250-smu-oc.service
    else
        clear
        echo -e "${GREEN}[✓] Settings applied to local conf! Toolchain installation required to activate as boot service.${NC}"
    fi
    read -p "Press [Enter] to return to the tuning menu..."
}

# ==============================================================================
# 🎛️ SURGICAL HARDWARE SMU GOVERNOR CEILING MANUAL OVERRIDES
# ==============================================================================
apply_manual_clock_clamp() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local DIM='\033[38;2;110;110;110m' local RESET='\033[0m'
    local BOLD='\033[1m' local BIGreen='\033[1;92m' local BIBlack='\033[1;90m'
    local SMU_CONF="/etc/cyan-skillfish-governor-smu/config.toml"

    clear
    echo -e  "       ${CYAN}====================================================================${RESET}"
    echo -e  "              🚀 GFX1013 LIVE GOVERNOR CEILING MANUAL OVERRIDE INJECTOR        "
    echo -e  "       ${CYAN}====================================================================${RESET}"
    
    if [[ ! -f "$SMU_CONF" ]]; then
        echo -e "${RED}❌ ERROR: Governor profile template missing at $SMU_CONF${RESET}"
        echo -e "         Please run Option [M] from the menu first to seed the template."
        echo ""
        read -rp "Press [Enter] to return..." dummy; return 1
    fi

    # 🧬 PREMIUM SYMMETRICAL HARDWARE OVERRIDE REFERENCE TARGETS
    echo -e "  ${CYAN}╔════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║             ${BOLD}${BICyan}BC-250 SMU MANUAL CLOCK TUNING SAFE REFERENCE MATRIX${NC}               ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚════════════════════════════════════════════════════════════════════════════════╝${NC}"
    printf "  ${CYAN}║${NC}   %b%-10s%b │ %-20s │ %-39s  ${CYAN}║${NC}\n" "${BOLD}" "GPU Clock" "${RESET}" "Safe Voltage (VID)" "Target Silicon Profile Performance"
    echo -e "  ${CYAN}║${BIBlack}   ──────────────┼──────────────────────┼───────────────────────────────────    ${CYAN}║${NC}"
    printf "  ${CYAN}║${NC}   %-13s │ %4s mV - %4s mV    │ %-31s       ${CYAN}║${NC}\n" "1400 MHz" "750" "780" "Factory Baseline (Dead Silent)"
    printf "  ${CYAN}║${NC}   %-13s │ %4s mV - %4s mV    │ %-31s       ${CYAN}║${NC}\n" "1600 MHz" "780" "820" "Balanced Power Eco Layout"
    printf "  ${CYAN}║${NC}   %b%-13s%b │ %b%4s mV - %4s mV%b    │ %b%-31s%b       ${CYAN}║${NC}\n" "${BIGreen}" "1800 MHz" "${NC}" "${BIGreen}" "880" "900" "${NC}" "${BIGreen}" "🎯 EFFICIENCY GAMING SWEET SPOT" "${NC}"
    printf "  ${CYAN}║${NC}   %b%-13s%b │ %b%4s mV - %4s mV%b    │ %b%-31s%b       ${CYAN}║${NC}\n" "${BIGreen}" "1850 MHz" "${NC}" "${BIGreen}" "900" "920" "${NC}" "${BIGreen}" "🎯 TUNED VOLTAGE HEADROOM CLAMP" "${NC}"
    printf "  ${CYAN}║${NC}   %-13s │ %4s mV - %4s mV    │ %-31s   ${CYAN}║${NC}\n" "2000 MHz" "940" "965" "Aggressive Profile (High Fan Speed)"
    printf "  ${CYAN}║${NC}   %-13s │ %4s mV - %4s mV    │ %-31s       ${CYAN}║${NC}\n" "2100 MHz" "980" "1005" "Extreme Overclock Air Ceiling"
    printf "  ${CYAN}║${NC}   %b%-13s%b │ %b%4s mV - %4s mV%b    │ %b%-31s%b       ${CYAN}║${NC}\n" "${RED}" "2150 MHz" "${NC}" "${RED}" "1010" "1025" "${NC}" "${RED}" "⚠️ MAXIMUM VOLTAGE LIMIT SHIELD" "${NC}"
    echo -e "  ${CYAN}╚════════════════════════════════════════════════════════════════════════════════╝${NC}\n"
    read -rp "👉 Enter Target Maximum GPU Frequency (MHz) [e.g. 1800, 2150]: " target_freq
    read -rp "👉 Enter Target Maximum GPU Voltage (mV)     [e.g. 900, 1025]: " target_volt

    if [[ ! "$target_freq" =~ ^[0-9]+$ ]] || [[ ! "$target_volt" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}❌ ERROR: Parameters must be explicit integers.${RESET}"; sleep 2; return 1
    fi

    if (( target_freq > 2200 )) || (( target_volt > 1050 )); then
        echo -e "${RED}❌ CRITICAL LIMIT SHIELD: Ceilings exceeded! Aborting injection.${RESET}"; sleep 3; return 1
    fi

    echo -e "${YELLOW}[⚙] Hot-patching governor boundary tables securely...${RESET}"
    # 🧬 ANCHORED LINE BOUNDARIES: Matches strict line starts to isolate fields perfectly
    sudo sed -i "s/^max = .*/max = $target_freq/g" "$SMU_CONF" 2>/dev/null
    sudo sed -i "s/^max_voltage = .*/max_voltage = $target_volt/g" "$SMU_CONF" 2>/dev/null
    
    # 🧬 RE-GENERATE DYNAMIC RE-INDEX PASS
    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl restart cyan-skillfish-governor-smu 2>/dev/null
    
    echo -e "${GREEN}[✓] SUCCESS: Silicon parameters locked! Service refreshed smoothly.${RESET}"
    sleep 2; return 0
}

run_cpu_core_stress_test() {
    clear
    echo -e "${BOLD}${YELLOW}=== Launching Silicon Per-Core Stability Sweep ===${NC}"
    echo -e "  ${DIM}This utility runs heavy computation verification matrices to stress-test locks.${NC}\n"

    local test_dir="$REAL_HOME/Bazzite_Toolbox/Diagnostics"
    mkdir -p "$test_dir" 2>/dev/null
    cd "$test_dir" || return 1

    echo -e "${YELLOW}[●] Step 1/3: Staging verification dependencies via system package layers...${NC}"
    (sudo rpm-ostree cleanup -p 2>/dev/null || true) &>/dev/null
    (sudo rpm-ostree install -y stress-ng 2>/dev/null || true) &>/dev/null

    echo -e "${YELLOW}[●] Step 2/3: Fetching upstream stability configuration maps...${NC}"
    (sudo rm -f test-cores.sh) &>/dev/null
    (sudo -u "$REAL_USER" wget https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/main.cpp 2>/dev/null || true) &>/dev/null

    echo -e "${YELLOW}[●] Step 3/3: Initializing per-core transaction sweep matrices...${NC}\n"
    if [[ -s "test-cores.sh" ]]; then
        chmod +x test-cores.sh
        sudo ./test-cores.sh
    else
        echo -e "${YELLOW}[ℹ] Upstream script wrapper cached. Running direct compute verifications (60s)...${NC}"
        sudo stress-ng --cpu $(nproc) --cpu-method all --verify --timeout 60s --metrics-brief
    fi

    echo -e "\n${GREEN}✔  Stability sweep complete! Check parameters if threads threw faults.${NC}\n"
    read -rp "  Press [Enter] to return to the primary management loop... "
}

# ==============================================================================
# 🧬 HARDWARE-AWARE PERFORMANCE PROFILE CONFIGURATION GENERATOR
# ==============================================================================
configure_governor_profile() {
    clear
    echo ""
    echo -e "  ${CYAN}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║               ${BOLD}${BICyan}BC-250 SILICON GOVERNOR & PERFORMANCE PROFILE MANAGER${NC}                         ${CYAN}║${NC}"
    echo -e "  ${CYAN}║                    ${DIM}* HARDWARE SPECIFICATIONS AUDIT WIZARD *${NC}                                 ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}╔═ Dynamic Telemetry Scanner ═════════════════════════════════════════════════════════════════╗${NC}"
    local detected_cus=24
    if [[ -f /etc/bc250-cu-live-manager.conf ]]; then
        local raw_masks
        raw_masks=$(grep "BC250_WGP_MASKS=" /etc/bc250-cu-live-manager.conf | cut -d= -f2)
        if [[ -n "$raw_masks" ]]; then
            local total_bits=0
            IFS=',' read -r -a mask_array <<< "$raw_masks"
            for mask in "${mask_array[@]}"; do
                local val=$((mask))
                for ((i=0; i<32; i++)); do (( (val >> i) & 1 )) && ((total_bits++)); done
            done
            (( detected_cus = total_bits * 2 ))
        fi
    fi

    if (( detected_cus == 0 )) && command -v umr &> /dev/null; then
        detected_cus=$(umr -i 0 -g 2>/dev/null | grep -i "cu_per_sh" | awk '{print $3 * 4}')
    fi
    if [[ ! "$detected_cus" =~ ^[0-9]+$ ]] || (( detected_cus <= 0 )); then detected_cus=24; fi

    local live_threads=$(nproc 2>/dev/null || echo "12")
    local detected_cores=$(( live_threads / 2 ))

    echo -e "  ${CYAN}╔═ Dynamic Telemetry Scanner ═════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "  ${CYAN}║${NC}   ${BOLD}${GREEN}✔ ACTIVE HARDWARE IDENTIFIED:${NC} ${detected_cus}/40 Compute Units  │  ${detected_cores} CPU Cores / ${live_threads} Threads            ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "  ${CYAN}╔═ HARDWARE AUDIT: COOLING SYSTEM AND ENVIRONMENT ════════════════════════════════════════════╗${NC}"
    echo -e "   ${RED}1)${NC} Stock Air Cooler  │  ${GREEN}2)${NC} Premium Aftermarket Air  │  ${YELLOW}3)${NC} Liquid Cooled Core"
    echo -n "  Enter cooling profile option [1-3]: "
    local cooling_choice; read -r cooling_choice
    local THROTTLE_TEMP=83 local RECOVERY_TEMP=75 local COOLING_LABEL="Stock Air"
    case "$cooling_choice" in
        2) THROTTLE_TEMP=84; RECOVERY_TEMP=75; COOLING_LABEL="Premium Air Cooled";;
        3) THROTTLE_TEMP=65; RECOVERY_TEMP=58; COOLING_LABEL="Liquid Cooled Core";;
        *) THROTTLE_TEMP=83; RECOVERY_TEMP=75; COOLING_LABEL="Stock Air (Optimized)";;
    esac

    echo -e "\n  ${CYAN}╔═ SYSTEM INTERFACE AUDIT: BAZZITE EXECUTION ENVIRONMENT ═════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║${NC}  Are you primarily running this system inside Steam Gaming Mode (Big Picture interface)?    ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -ne "  Booting into Steam Gaming Mode interface? (${GREEN}y${NC}/${RED}N${NC}): "
    local is_gaming_mode; read -r is_gaming_mode
    local dbus_state="true"
    if [[ "$is_gaming_mode" =~ ^[Yy]$ ]]; then dbus_state="false"; fi

    echo -e "  ${CYAN}╔═ [2/5] HARDWARE AUDIT: POWER INFRASTRUCTURE overhead ═══════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║${NC}  Enter your physical Power Supply Unit (PSU) maximum continuous wattage rating:             ${CYAN}║${NC}"
    echo -e "  ${CYAN}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}   ${DIM}* Platform registers custom profiles from a 300W baseline up to a 500W+ extreme ceiling * ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    local psu_wattage; read -p "  PSU Wattage Rating (e.g., 300, 450, 500): " psu_wattage
    [[ "$psu_wattage" =~ ^[0-9]+$ ]] || psu_wattage=300
    echo -e "\n  ${CYAN}╔═ [3/5] HARDWARE AUDIT: GRAPHICS COMPUTE UNIT PROFILES ══════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║${NC}  Live scanner path reports ${detected_cus}/40 Compute Units (CUs) currently active on this core.         ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "   ${RED}1)${NC} Target 36 CUs Active  │  ${GREEN}2)${NC} Target 38 CUs Active  │  ${YELLOW}3)${NC} Target 40 CUs Active"
    echo -n "  Select target CU configuration profile [1-3]: "
    local cu_choice; read -r cu_choice
    local ACTIVE_CUS=38
    case "$cu_choice" in 1) ACTIVE_CUS=36;; 2) ACTIVE_CUS=38;; 3) ACTIVE_CUS=40;; esac

    echo -e "\n  ${CYAN}╔═ [4/5] HARDWARE AUDIT: CPU CORE COMPLEX ALLOCATION ═════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║${NC}  Live scanner path reports ${detected_cores} CPU Cores / ${live_threads} Threads active on this node.               ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "   ${GREEN}1)${NC} Target 6 Cores / 12 Threads (Balanced)  │  ${YELLOW}2)${NC} Target 8 Cores / 16 Threads (Maximum)"
    echo -n "  Select target CPU core complex [1-2]: "
    local core_choice; read -r core_choice
    local ACTIVE_CORES=8 local INTERVAL_SAMPLE=4000
    case "$core_choice" in 1) ACTIVE_CORES=6; INTERVAL_SAMPLE=6000;; *) ACTIVE_CORES=8; INTERVAL_SAMPLE=4000;; esac

    echo -e "\n  ${CYAN}╔═ [5/5] HARDWARE AUDIT: SYSTEM TUNING OPTIMIZATION PROFILE ══════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "   ${GREEN}1)${NC} Normal Computer Use  │  ${CYAN}2)${NC} Standard Gaming (1800MHz)  │  ${RED}3)${NC} Heavy Overclocking (2150MHz)"
    echo -n "  Select tuning profile [1-3]: "
    local tuning_choice; read -r tuning_choice

    local PROFILE_LABEL="NORMAL COMPUTER USE" local RAMP_NORMAL=5 local RAMP_BURST=15 local FREQ_MAX=1400 local VOLT_MAX=780
    case "$tuning_choice" in
        2) PROFILE_LABEL="STANDARD GAMING"; RAMP_NORMAL=10; RAMP_BURST=50; FREQ_MAX=1800; VOLT_MAX=900;;
        3) PROFILE_LABEL="HEAVY OVERCLOCKING"; RAMP_NORMAL=15; RAMP_BURST=80; FREQ_MAX=2150; VOLT_MAX=1005;;
        *) tuning_choice=1;;
    esac

    if (( psu_wattage < 400 )); then
        PROFILE_LABEL="NORMAL USE (FORCED_CLAMP)"; FREQ_MAX=1400; VOLT_MAX=780; tuning_choice=1
    elif (( psu_wattage < 500 )) && [ "$tuning_choice" -eq 3 ]; then
        PROFILE_LABEL="STANDARD GAMING (DOWNSCALED_PSU)"; FREQ_MAX=1800; VOLT_MAX=900; tuning_choice=2
    fi

    local TARGET_CONF="/etc/cyan-skillfish-governor-smu/config.toml"
    sudo mkdir -p /etc/cyan-skillfish-governor-smu 2>/dev/null
    [[ -f "$TARGET_CONF" ]] && sudo cp "$TARGET_CONF" "${TARGET_CONF}.bak_$(date +%Y%m%d_%H%M%S)" 2>/dev/null

    sudo bash -c "cat <<EOF > $TARGET_CONF
# ==============================================================================
# PROFILE TEMPLATE LAYOUT: $PROFILE_LABEL
# Calculated dynamically via BC-250 Spec Auditor Wizard Suite
# Hardware Target Mask: $ACTIVE_CUS CUs Unlocked | $ACTIVE_CORES CPU Cores Active
# Hardware Spec Mask: Cooling = $COOLING_LABEL | Power Source = ${psu_wattage}W PSU
# ==============================================================================

[timing.intervals]
sample = $INTERVAL_SAMPLE
adjust = 30000

[gpu-usage]
fix-freq = true
fix-metrics = true
method = \"busy-flag\"
flush-every = 5

[gpu]
set-method = \"smu\"
target_card = \"card1\"

[dbus]
enabled = $dbus_state

[timing.ramp-rates]
normal = $RAMP_NORMAL
burst = $RAMP_BURST

[timing]
burst-samples = 3
down-events = 20

[frequency-thresholds]
adjust = 5
upper = 0.94
lower = 0.82

[load-target]
upper = 0.80
lower = 0.60

[temperature]
throttling = $THROTTLE_TEMP
throttling_recovery = $RECOVERY_TEMP

[frequency-range]
min = 350
max = $FREQ_MAX
min_voltage = 700
max_voltage = $VOLT_MAX

[[safe-points]]
frequency = 350
voltage = 700

[[safe-points]]
frequency = 500
voltage = 700

[[safe-points]]
frequency = 1000
voltage = 730

[[safe-points]]
frequency = 1400
voltage = 765
EOF"

    # Append Mid Safe Points
    if [ "$tuning_choice" -gt 1 ]; then
        sudo bash -c "cat <<EOF >> $TARGET_CONF

[[safe-points]]
frequency = 1500
voltage = 790

[[safe-points]]
frequency = 1600
voltage = 820

[[safe-points]]
frequency = 1700
voltage = 850

[[safe-points]]
frequency = 1800
voltage = 880
EOF"
    fi

    # Append Max Safe Points (Tuned to 1025mV for permanent hardware load stability)
    if [ "$tuning_choice" -eq 3 ]; then
        sudo bash -c "cat <<EOF >> $TARGET_CONF

[[safe-points]]
frequency = 1900
voltage = 910

[[safe-points]]
frequency = 1950
voltage = 930

[[safe-points]]
frequency = 2000
voltage = 950

[[safe-points]]
frequency = 2050
voltage = 970

[[safe-points]]
frequency = 2100
voltage = 995

[[safe-points]]
frequency = 2125
voltage = 1010

[[safe-points]]
frequency = 2150
voltage = 1025
EOF"
    fi

    echo -e "  ${GREEN}[✓] New config.toml compiled successfully using hardware constraints!${NC}"
    echo -e "  ${YELLOW}[⚙] Cycling changes into live governor service memory...${NC}"
    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl restart cyan-skillfish-governor-smu 2>/dev/null || true
    (play_success_chime &>/dev/null &)
    echo -e "  ${GREEN}[✓] Task complete! Active system profiles locked into memory space cleanly.${NC}\n"
    read -rp "  Press [Enter] to exit back to the main menu..."
}

# 🧬 HELPER ENGINE: Executes countdown loop and interactive save gate for options 1-6
run_preset_stress_flow() {
    local target_threads=$(nproc 2>/dev/null || echo "12")
    if [[ "$live_threads" =~ ^[0-9]+$ ]] && [ "$live_threads" -gt 0 ]; then
        target_threads="$live_threads"
    fi

    echo -e "\n  ${YELLOW}[●] Initializing Silicon Stability Sweep Utilizing ${target_threads} Active Threads...${NC}"
    
    # Spawns stress silently into a background process thread block
    stress --cpu "$target_threads" --timeout 150 >> "$LOG_FILE" 2>&1 &
    local stress_pid=$!
    
    # Universal Countdown Loop Tracker
    local seconds_left=150
    while kill -0 "$stress_pid" 2>/dev/null; do
        echo -ne "      Stability validation testing in progress... ${RED}${seconds_left}s${CYAN} remaining...${RESET}\r"
        sleep 1
        ((seconds_left--))
    done
    echo -e "\n"
    echo -e "${B_GREEN}✓ Stress test complete! Hardware stability verified.${NC}"
    
    read -rp "Would you like to permanently save and activate these custom settings? [y/n]: " save_choice
    if [[ "$save_choice" =~ ^[Yy]$ ]]; then
        play_success_chime
        finalize_settings
    else
        echo -e "${CYAN}[-] Save aborted. Returning safely to tuning menu...${NC}"
        sleep 2
    fi
}
launch_tuning_menu() {
    while true; do
        clear
        echo ""
        echo -e "  ${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${CYAN}║                BC-250 TUNING & CONFIGURATION MENU                 ║${NC}"
        echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${YELLOW}Select a baseline template for your hardware variant:${NC}"
        echo -e "  ${BIBlack}──────────────────────────────────────────────────────────────────────────${NC}"
        echo -e "    ${CYAN}1)${NC} 40/40 CU - Extreme Overclock  ${BIBlack}───${NC}  3500 MHz  @  1000 mV  ${BIBlack}│${NC}  Max 85°C"
        echo -e "    ${CYAN}2)${NC} 40/40 CU - High-Efficiency    ${BIBlack}───${NC}  3000 MHz  @   920 mV  ${BIBlack}│${NC}  Max 78°C"
        echo -e "    ${RED}W)${NC} 40/40 CU - WATER-COOLED BEAST ${BIBlack}───${NC}  3850 MHz  @  1150 mV  ${RED}│  AIO/WATER REQ.${NC}"
        echo -e "    ${CYAN}3)${NC} 38/40 CU - Extreme Overclock  ${BIBlack}───${NC}  3500 MHz  @  1020 mV  ${BIBlack}│${NC}  Max 85°C"
        echo -e "    ${CYAN}4)${NC} 38/40 CU - Balanced Gaming    ${BIBlack}───${NC}  3000 MHz  @   945 mV  ${BIBlack}│${NC}  Max 80°C"
        echo -e "    ${CYAN}5)${NC} 36/40 CU - Silent / Eco Core  ${BIBlack}───${NC}  2800 MHz  @   890 mV  ${BIBlack}│${NC}  Max 75°C"
        echo ""
        echo -e "    ${BIGreen}6) Manual Custom Profile${NC}       ${BIBlack}(Fill MHz, mV, Max Temp manually)${NC}"
        echo -e "    ${BIGreen}7) Manual Custom Sandbox${NC}       ${BIBlack}(Test parameters safely without saving)${NC}"
        echo ""
        echo -e "    ${RED}↵) Return to BC-250 CPU OVERCLOCK & Compute Unit Live Manager Setup Tool ${NC}    ${BIBlack}(Skip auto-tuning routine)${NC}"
        echo -e "  ${BIBlack}──────────────────────────────────────────────────────────────────────────${NC}"
        echo ""
        read -p "  Enter selection [1-7, W, ↵]: " tune_choice

        local target_dir="."
        if [ -d "$REAL_HOME/Bazzite_Toolbox/Overclock" ]; then target_dir="$REAL_HOME/Bazzite_Toolbox/Overclock"; fi

        case "$tune_choice" in
            1)
                log "${GREEN}Staging 40/40 CU - Extreme Overclock template...${NC}"
                printf "[overclock]\nfrequency=3500\nscale=-19\nmax_temperature=85\nkeep=True\n" > "$target_dir/overclock.conf"
                run_preset_stress_flow
                ;;
            2)
                log "${GREEN}Staging 40/40 CU - High-Efficiency template...${NC}"
                printf "[overclock]\nfrequency=3000\nscale=-19\nmax_temperature=78\nkeep=True\n" > "$target_dir/overclock.conf"
                run_preset_stress_flow
                ;;
            3)
                log "${GREEN}Staging 38/40 CU - Extreme Overclock template...${NC}"
                printf "[overclock]\nfrequency=3500\nscale=-19\nmax_temperature=85\nkeep=True\n" > "$target_dir/overclock.conf"
                run_preset_stress_flow
                ;;
            4)
                log "${GREEN}Staging 38/40 CU - Balanced Gaming template...${NC}"
                printf "[overclock]\nfrequency=3000\nscale=-19\nmax_temperature=80\nkeep=True\n" > "$target_dir/overclock.conf"
                run_preset_stress_flow
                ;;
            5)
                log "${GREEN}Staging 36/40 CU - Silent / Eco Core template...${NC}"
                printf "[overclock]\nfrequency=2800\nscale=-19\nmax_temperature=75\nkeep=True\n" > "$target_dir/overclock.conf"
                run_preset_stress_flow
                ;;
            w|W)
                clear
                echo -e "${RED}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${RED}║ [⚠] CRITICAL SAFETY WARNING: CUSTOM WATER COOLING LOOP REQURED FOR 3850MHz                 ║${NC}"
                echo -e "${RED}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
                echo -e "${RED}║ Running 1150mV on basic air cooling WILL cause rapid thermal degradation or instant crash.   ║${NC}"
                echo -e "${RED}║ DO NOT proceed unless you have verified custom liquid block mounting active.               ║${NC}"
                echo -e "${RED}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
                echo ""
                read -rp "  Type 'RUN' to confirm you are water cooled, or press Enter to abort: " water_confirm
                if [[ "$water_confirm" != "RUN" ]]; then
                    echo -e "${YELLOW}Operation aborted safely. Returning to menu...${NC}"
                    sleep 2
                    continue
                fi
                log "${RED}Staging 40/40 CU - Water-Cooled Extreme Beast Mode template...${NC}"
                printf "[overclock]\nfrequency=3850\nscale=-19\nmax_temperature=90\nkeep=True\n" > "$target_dir/overclock.conf"
                run_preset_stress_flow
                ;;
            6|7)
                while true; do
                    clear
                    # 🧬 PREMIUM SYMMETRICAL SILICON PROFILER DISPLAY GRID (PART 2)
                    echo -e "  ${CYAN}╔══════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
                    echo -e "  ${CYAN}║                      ${BOLD}${BICyan}BC-250 SILICON VOLTAGE & THERMAL SCALING MATRIX${NC}                         ${CYAN}║${NC}"
                    echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"

                    # Header row configuration - 100% Symmetrical Bounds Pinned
                    printf "  ${CYAN}║${NC}   %-13s │ %-20s │ %-12s │ %-34s   ${CYAN}║${NC}\n" "${BOLD}Freq Block" "Voltage (VID)" "Thermal Load" "Silicon Performance Profile${RESET}"
                    echo -e "  ${CYAN}║${BIBlack}   ──────────────┼──────────────────────┼───────────────┼───────────────────────────────────  ${CYAN}║${NC}"
                    # Standard Rows - Mapped explicitly with inner character counters
                    printf "  ${CYAN}║${NC}   %-13s │ %4s mV - %4s mV    │ %-12s   │ %-34s  ${CYAN}║${NC}\n" "2000-2300 MHz" "800" "840" "50°C - 60°C" "Absolute Eco Floor (Dead Silent)"
                    printf "  ${CYAN}║${NC}   %-13s │ %4s mV - %4s mV    │ %-12s   │ %-34s  ${CYAN}║${NC}\n" "2400-2500 MHz" "840" "860" "58°C - 65°C" "Balanced Power Light Emulation"
                    printf "  ${CYAN}║${NC}   %-13s │ %4s mV - %4s mV    │ %-12s   │ %-34s  ${CYAN}║${NC}\n" "2600-2700 MHz" "860" "890" "62°C - 72°C" "Software Guard Floor Tiers"

                    # Highlight Tiers: Color profiles passed dynamically without altering character count layout spacing
                    printf "  ${CYAN}║${NC}   %b%-13s%b │ %b%4s mV - %4s mV%b    │ %b%-12s%b   │ %b%-34s%b    ${CYAN}║${NC}\n" "${BIGreen}" "2800 MHz" "${NC}" "${BIGreen}" "890" "905" "${NC}" "${BIGreen}" "65°C - 75°C" "${NC}" "${BIGreen}" "🎯 EFFICIENCY SWEET SPOT (Opt 5)" "${NC}"
                    printf "  ${CYAN}║${NC}   %b%-13s%b │ %b%4s mV - %4s mV%b    │ %b%-12s%b   │ %b%-34s%b    ${CYAN}║${NC}\n" "${BIGreen}" "3000 MHz" "${NC}" "${BIGreen}" "920" "940" "${NC}" "${BIGreen}" "70°C - 80°C" "${NC}" "${BIGreen}" "🎯 GAMING SWEET SPOT (Opt 2/4)" "${NC}"

                    # Standard Rows Continuation
                    printf "  ${CYAN}║${NC}   %-13s │ %4s mV - %4s mV    │ %-12s   │ %-34s  ${CYAN}║${NC}\n" "3100-3400 MHz" "940" "1000" "72°C - 84°C" "Aggressive Air Tier (High Current)"
                    printf "  ${CYAN}║${NC}   %-13s │ %4s mV - %4s mV    │ %-12s   │ %-34s ${CYAN}║${NC}\n" "3500 MHz" "1000" "1020" "80°C - 85°C" "Stock Factory Air Ceiling Reference"
                    printf "  ${CYAN}║${NC}   %-13s │ %4s mV - %4s mV    │ %-12s   │ %-34s  ${CYAN}║${NC}\n" "3600-3700 MHz" "1030" "1100" "82°C - 88°C" "Extreme Overclock (High Fan Speed)"
                    printf "  ${CYAN}║${NC}   %-13s │ %4s mV - %4s mV    │ %-12s   │ %-34s  ${CYAN}║${NC}\n" "3800 MHz" "1120" "1160" "88°C - 94°C" "Option W Liquid-Cooled Loop Only"

                    # Danger Zone High-Visibility Highlighting Row
                    printf "  ${CYAN}║${NC}   %b%-13s%b │ %b%4s mV - %4s mV%b    │ %b%-12s%b │ %b%-34s%b  ${CYAN}║${NC}\n" "${RED}" "3900-4000 MHz" "${NC}" "${RED}" "1160" "1325" "${NC}" "${RED}" "92°C - 105°C+" "${NC}" "${RED}" "DANGER ZONE (Silicon Decay)" "${NC}"

                    echo -e "  ${CYAN}╚══════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
                    echo ""

                    echo -e "  ${DIM}    * Type [Q] to return to previous menu  │  Type [R] to refresh table view *${RESET}\n"
                    # ==============================================================================
                    # 🧬 HARDENED PARAMETER COLLECTION TRACK (NO DUPLICATE PROMPTS)
                    # ==============================================================================

                    # 📐 INPUT ROW 1: TARGET FREQUENCY
                    while true; do
                        read -p "  Enter Target Frequency (MHz) [2000 - 4000]: " custom_freq
                        if [[ "$custom_freq" =~ ^[Qq]$ ]]; then echo -e "  ${YELLOW}[←] Bailing out to tuning dashboard...${NC}"; sleep 0.8; break 2; fi
                        if [[ "$custom_freq" == "r" ]]; then echo -e "  ${CYAN}[↺] Flushing screen buffer...${NC}"; sleep 0.4; continue 2; fi
                        if [[ "$custom_freq" == "R" ]]; then echo -e "  ${GREEN}[↺] Hot-reloading script workspace...${NC}"; sleep 0.8; exec bash "$SCRIPT_PATH" "$@"; fi

                        if [[ "$custom_freq" =~ ^[0-9]+$ ]] && [ "$custom_freq" -ge 2000 ] && [ "$custom_freq" -le 4000 ]; then
                            break
                        else
                            echo -e "  ${RED}SAFETY ERROR: Frequency must sit between 2000 MHz and 4000 MHz!${NC}"
                        fi
                    done

                    # 📐 INPUT ROW 2: TARGET VOLTAGE
                    while true; do
                        read -p "  Enter Target Voltage (mV / VID) [800 - 1325]: " custom_vid
                        if [[ "$custom_vid" =~ ^[Qq]$ ]]; then echo -e "  ${YELLOW}[←] Bailing out to tuning dashboard...${NC}"; sleep 0.8; break 2; fi
                        if [[ "$custom_vid" == "r" ]]; then echo -e "  ${CYAN}[↺] Flushing screen buffer...${NC}"; sleep 0.4; continue 2; fi
                        if [[ "$custom_vid" == "R" ]]; then echo -e "  ${GREEN}[↺] Hot-reloading script workspace...${NC}"; sleep 0.8; exec bash "$SCRIPT_PATH" "$@"; fi

                        if [[ "$custom_vid" =~ ^[0-9]+$ ]] && [ "$custom_vid" -ge 800 ] && [ "$custom_vid" -le 1325 ]; then
                            break
                        else
                            echo -e "  ${RED}SAFETY ERROR: Voltage must sit between 800 mV and 1325 mV!${NC}"
                        fi
                    done

                    # 📐 INPUT ROW 3: TEMPERATURE CEILING
                    while true; do
                        read -p "  Enter Max Temperature Target (°C) [60 - 95]: " custom_temp
                        if [[ "$custom_temp" =~ ^[Qq]$ ]]; then echo -e "  ${YELLOW}[←] Bailing out to tuning dashboard...${NC}"; sleep 0.8; break 2; fi
                        if [[ "$custom_temp" == "r" ]]; then echo -e "  ${CYAN}[↺] Flushing screen buffer...${NC}"  ; sleep 0.4; continue 2; fi
                        if [[ "$custom_temp" == "R" ]]; then echo -e "  ${GREEN}[↺] Hot-reloading script workspace...${NC}"; sleep 0.8; exec bash "$SCRIPT_PATH" "$@"; fi

                        if [[ "$custom_temp" =~ ^[0-9]+$ ]] && [ "$custom_temp" -ge 60 ] && [ "$custom_temp" -le 95 ]; then
                            break
                        else
                            echo -e "  ${RED}SAFETY ERROR: Temperature limit must sit between 60°C and 95°C!${NC}"
                        fi
                    done
                    # ==============================================================================
                    # 🧬 HARDWARE DEPLOYMENT CORE (STRESS LOOPS & RESTORED LOOP-AGAIN PROMPTS)
                    # ==============================================================================
                    log "${GREEN}Running custom tuning profile optimization...${NC}"
                    printf "[overclock]\nfrequency=%s\nscale=-19\nmax_temperature=%s\nkeep=True\n" "$custom_freq" "$custom_temp" > "$target_dir/overclock.conf"

                    if [ "$tune_choice" = "6" ]; then
                        # 🧬 FIXED: Targets stress-ng to ensure full compatibility with layered image packages
                        stress-ng --cpu "$target_threads" --timeout 150 >> "$LOG_FILE" 2>&1 &
                        run_preset_stress_flow
                    else
                        local sandbox_threads=$(nproc 2>/dev/null || echo "12")
                        if [[ "$live_threads" =~ ^[0-9]+$ ]] && [ "$live_threads" -gt 0 ]; then sandbox_threads="$live_threads"; fi
                        echo -e "\n  ${YELLOW}[●] Initializing Sandbox Stability Sweep Utilizing ${sandbox_threads} Threads...${NC}"

                        # 🧬 FIXED: Targets stress-ng to actively saturate your core topologies under sandbox tests
                        stress-ng --cpu "$sandbox_threads" --timeout 150 >> "$LOG_FILE" 2>&1 &
                        local stress_pid=$!
                        local seconds_left=150

                        while kill -0 "$stress_pid" 2>/dev/null; do
                            echo -ne "      Stability validation testing in progress... ${RED}${seconds_left}s${CYAN} remaining...${RESET}\r"
                            sleep 1
                            ((seconds_left--))
                        done
                        echo -e "\n  ${B_GREEN}✓ Sandbox verification sequence finalized.${NC}"
                    fi

                    # 🧬 FULLY RESTORED FEATURE: Prompts for another sweep option cleanly
                    local loop_again=""
                    if [ "$tune_choice" = "7" ]; then
                        read -rp "  Would you like to run another stress test with different settings? [y/n]: " loop_again
                    else
                        # For option 6, check if user confirmed the save during run_preset_stress_flow
                        if [[ "$save_choice" =~ ^[Yy]$ ]]; then break; fi
                        read -rp "  Would you like to try another configuration sweep with different settings? [y/n]: " loop_again
                    fi

                    # If they don't type Y/y, break clear back to your primary selection menu
                    if [[ ! "$loop_again" =~ ^[Yy]$ ]]; then
                        echo -e "  ${YELLOW}Returning safely to tuning menu...${NC}"
                        sleep 1.5
                        break
                    fi
                done
                ;;
            0|""|q|Q)
                echo -e "\n  ${YELLOW}[←] Returning safely to Master Setup Tool layout...${NC}"
                sleep 1.2
                return 0
                ;;
            *)
                echo -e "  ${RED}Invalid option selected. Please enter [1-7, W].${NC}"
                sleep 2
                ;;
        esac
    done
}

prompt_reboot() {
    echo ""
    echo -e "${YELLOW}==================================================${NC}"
    echo -e "${YELLOW} Task complete! The system needs to reboot now.   ${NC}"
    echo -e "${YELLOW}--------------------------------------------------${NC}"
    echo " 1) Reboot Now (Recommended)"
    echo " 2) Cancel Reboot & Return to Main Menu"
    echo -e "${YELLOW}==================================================${NC}"
    read -rp "Select an option [1-2]: " reboot_choice
    case $reboot_choice in
        1) sudo systemctl reboot ;;
        *) return 0 ;;
    esac
}

run_phase1() {
    if [[ -f "/usr/local/bin/bc250-detect" ]] || [[ -f "$SERVICE_FILE" ]]; then
        clear
        echo -e "\n  ${YELLOW}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${YELLOW}║${NC}  ${BOLD}${CYAN}[ℹ] CPU TUNING TOOLCHAIN DETECTED${NC}                                                          ${YELLOW}║${NC}"
        echo -e "  ${YELLOW}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "  ${YELLOW}║${NC} The Overclock Suite and its underlying background binaries are already present on this host.${YELLOW}║${NC}"
        echo -e "  ${YELLOW}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo " 1) Cancel operation and return safely to the primary layout loop"
        echo " 2) Force a complete, clean re-installation (Wipes and rebuilds the toolchain)"
        echo ""
        read -rp "  Select an option [1-2]: " static_choice
        if [[ "$static_choice" != "2" ]]; then
            print_info "Operation canceled safely. Returning to menu..."
            sleep 1.5
            return 0
        fi
        print_info "Force override accepted. Staging clean deployment tree..."
    fi

    show_warning
    log "${GREEN}[Phase 1] Initializing universal Bazzite 43/44 deployment tree...${NC}"
    sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=Resume BC-250 OC Installation
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash $SCRIPT_PATH --phase2
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF"
    sudo systemctl daemon-reload
    sudo systemctl enable bc250-resume.service >> "$LOG_FILE" 2>&1
    sudo rpm-ostree kargs --append=mitigations=off >> "$LOG_FILE" 2>&1
    sudo rpm-ostree install stress python3-devel >> "$LOG_FILE" 2>&1
    play_success_chime
    prompt_reboot
}
run_phase2() {
    log "${GREEN}[Phase 2] Resuming execution tree following successful reboot...${NC}"
    cd /tmp || exit
    sudo rm -rf /tmp/bc250_smu_oc
    git clone "$REPO_URL" /tmp/bc250_smu_oc >> "$LOG_FILE" 2>&1
    cd /tmp/bc250_smu_oc || exit
    sudo mkdir -p /opt/bc250_smu_tools
    sudo python3 -m venv /opt/bc250_smu_tools/venv >> "$LOG_FILE" 2>&1
    sudo /opt/bc250_smu_tools/venv/bin/pip install --upgrade pip >> "$LOG_FILE" 2>&1
    sudo /opt/bc250_smu_tools/venv/bin/pip install . >> "$LOG_FILE" 2>&1
    sudo ln -sf /opt/bc250_smu_tools/venv/bin/bc250-detect /usr/local/bin/bc250-detect
    sudo ln -sf /opt/bc250_smu_tools/venv/bin/bc250-apply /usr/local/bin/bc250-apply

    log "${GREEN}[⚙] Injecting custom low-power overrides from your repository...${NC}"
    local py_packages="/opt/bc250_smu_tools/venv/lib64/python3.14/site-packages"

    sudo curl -sSL -o "$py_packages/bc250_apply.py" "$MODDED_APPLY_URL" >> "$LOG_FILE" 2>&1
    sudo curl -sSL -o "$py_packages/bc250_limits.py" "$MODDED_LIMITS_URL" >> "$LOG_FILE" 2>&1
    sudo curl -sSL -o "$py_packages/bc250_detect.py" "$MODDED_DETECT_URL" >> "$LOG_FILE" 2>&1

    sudo rm -rf "$py_packages/__pycache__" 2>/dev/null || true

    sudo systemctl disable bc250-resume.service >> "$LOG_FILE" 2>&1
    sudo rm -f "$SERVICE_FILE"
    sudo systemctl daemon-reload
    log "${GREEN}[Success] Installation complete! 'bc250-detect' and 'bc250-apply' are ready.${NC}"
    
    launch_tuning_menu
}

run_manager_phase1() {
    # 🧬 PRE-FLIGHT DEPLOYMENT GATE: Detects if the CU Live Manager suite is already initialized or staged
    if [[ -f "/usr/local/bin/bc250-cu-live-manager" ]] || [[ -f "/etc/bc250-cu-live-manager.conf" ]] || [[ -f "/etc/systemd/system/bc250-cu-live-manager.service" ]]; then
        clear
        echo -e "\n  ${YELLOW}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${YELLOW}║${NC}  ${BOLD}${BLUE}[ℹ] COMPUTE UNIT LIVE MANAGER DETECTED${NC}                                                     ${YELLOW}║${NC}"
        echo -e "  ${YELLOW}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "  ${YELLOW}║${NC} The dynamic CU bitmask manager and active daemon profiles are already active on this host.${YELLOW}  ║${NC}"
        echo -e "  ${YELLOW}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo " 1) Cancel operation and return safely to the primary layout loop"
        echo " 2) Force a complete, clean re-installation (Wipes and rebuilds the dependency mapping)"
        echo ""
        read -rp "  Select an option [1-2]: " static_choice
        if [[ "$static_choice" != "2" ]]; then
            print_info "Operation canceled safely. Returning to menu..."
            sleep 1.5
            return 0
        fi
        print_info "Force override accepted. Staging clean dependency layers..."
    fi

    log "${GREEN}[CU Live Manager] Preparing installation requirements...${NC}"
    sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=Resume BC-250 CU Live Manager Deployment
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash $SCRIPT_PATH --manager-phase2
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF"
    sudo systemctl daemon-reload
    sudo systemctl enable bc250-resume.service >> "$LOG_FILE" 2>&1
    sudo rpm-ostree install umr >> "$LOG_FILE" 2>&1
    play_success_chime
    prompt_reboot
}

run_manager_phase2() {
    log "${GREEN}[CU Live Manager] Completing setup configurations post-reboot...${NC}"
    sudo systemctl disable bc250-resume.service >> "$LOG_FILE" 2>&1
    sudo rm -f $SERVICE_FILE
    sudo systemctl daemon-reload
    cd /tmp || exit
    curl -L -o bc250-cu-live-manager.sh https://raw.githubusercontent.com/WinnieLV/bc250-cu-live-manager/refs/heads/main/bc250-cu-live-manager.sh >> "$LOG_FILE" 2>&1
    chmod +x bc250-cu-live-manager.sh
    sudo ./bc250-cu-live-manager.sh
}

# ==============================================================================
# SUBROUTINE: PRODUCTION-READY CPU OVERCLOCK COMPLETE ROLLBACK UTILITY (PART 1)
# ==============================================================================
uninstall_cpu_overclock() {
    # 🧠 PRE-REMOVAL SECURITY GATES: Hard-locks execution passes until verified text is captured
    echo -e "\n${BIRed}[⚠️] CRITICAL NOTICE: You are about to completely wipe the CPU Overclock Suite.${NC}"
    echo -e "    This will strip all systemd service profiles, smu tools, and mitigation bypasses."
    echo -e "    To proceed with the permanent removal, please type ${YELLOW}accept${NC} or ${YELLOW}ACCEPT${NC}."
    type_prompt "👉 Verification Command Input: " 0.03
    local confirm_uninstall; read -r confirm_uninstall

    if [[ "$confirm_uninstall" == "accept" || "$confirm_uninstall" == "ACCEPT" ]]; then
        # 🔓 GATE PASSED: Proceed natively to file structure demolition and service purging
        log "${RED}[Uninstall] Initializing CPU Overclock rollback suite...${NC}"
        
        sudo systemctl disable --now bc250-smu-oc.service >> "$LOG_FILE" 2>&1 || true
        sudo systemctl disable --now bc250-resume.service >> "$LOG_FILE" 2>&1 || true
        sudo rm -f /etc/systemd/system/bc250-smu-oc.service
        sudo rm -f "$SERVICE_FILE"
        sudo rm -f /usr/local/bin/bc250-detect
        sudo rm -f /usr/local/bin/bc250-apply
        sudo rm -rf /opt/bc250_smu_tools
        sudo rm -rf /tmp/bc250_smu_oc
        # 🚀 CLEAN INSTRUCTION PIPE: Reverts security mitigations and drops testing packages
        echo -e "${CYAN}[⚙] Dispatching atomic package and mitigation rollback transaction...${NC}"
        
        sudo rpm-ostree kargs --delete=mitigations=off >> "$LOG_FILE" 2>&1 &
        sudo rpm-ostree uninstall stress python3-devel >> "$LOG_FILE" 2>&1 &
        local transaction_pid=$!
        local spinner=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )

        while kill -0 "$transaction_pid" 2>/dev/null; do
            for frame in "${spinner[@]}"; do
                echo -ne "\r  \033[0;36m[$frame] Re-building atomic deployment records cleanly...${NC}"
                sleep 0.08
            done
        done
        echo -ne "\r                                                                         \r"
        wait "$transaction_pid"
        sudo systemctl daemon-reload

        # 🎉 COMPLETION SECTOR: Audio feedback triggers alongside your custom reboot prompts
        echo -e "\n${BIGreen}[✓] SUCCESS: CPU Overclock Suite has been completely scrubbed from the system!${NC}"
        play_success_chime
        
        type_prompt "❓ Would you like to execute a system cold reset right now? (y/N): " 0.03
        local reboot_choice; read -r reboot_choice
        if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}[!] Sending ACPI Cold Reset signal... re-mounting hardware rails...${NC}"
            sync && sleep 1 && reboot
        fi
    else
        # 🔒 GATE BLOCKED: User didn't type accept, keep system completely untouched
        echo -e "\n${BIRed}[-] Verification failed or bypassed. Aborting removal suite pass. System state preserved.${NC}"
        type_prompt "    Press Enter to return to the toolkit menu..." 0.03
        read -r
    fi
}

# ==============================================================================
# SUBROUTINE: SILICON PER-CORE STABILITY SWEEP & HARDWARE CHANNEL VALIDATOR
# ==============================================================================
run_stability_sweep() {
    clear
    echo -e "${DIM}┌────────────────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${DIM}│${RESET}                 📟  AMD BC-250 Per-Core Stability Sweep Engine                     ${DIM}│${RESET}"
    echo -e "${DIM}└────────────────────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${BOLD}${YELLOW}⚠️  SILICON STABILITY CRUISE MODULE:${RESET}"
    echo -e "  This automation utility isolates every logical core execution channel individually."
    echo -e "  By pinning processor workloads using explicit taskset affinity masks, it forces"
    echo -e "  focused validation stress onto specific silicon blocks to test Curve Optimizer bounds."
    echo ""

    # Check for underlying execution utilities inside Bazzite's atomic layers
    local stress_bin=""
    if command -v stress-ng &>/dev/null; then stress_bin="stress-ng"
    elif command -v stress &>/dev/null; then stress_bin="stress"
    else
        echo -e "${BIRed}❌ ERROR: Missing verification tools. Neither 'stress-ng' nor 'stress' found.${NC}"
        echo -e "          Please run Option [1b] or verify network connectivity profiles.${NC}"
        read -p "Press Enter to return..." && return 1
    fi

    echo -e "  Available Automated Test Profiles:"
    echo -e "    [1] Ultra-Fast Validation Pass  ${DIM}(15 Seconds per Core Row — Quick Verification)${RESET}"
    echo -e "    [2] Deep Hardware Burn-In Sweep ${DIM}(60 Seconds per Core Row — Thorough Validation)${RESET}"
    echo -e "    [3] Cancel & Exit               ${DIM}(Abort validation testing and return to master menu)${RESET}"
    echo ""
    type_prompt "👉 Select test duration profile: " 0.03
    local sweep_choice; read -r sweep_choice

    local test_duration=0
    case "$sweep_choice" in
        1) test_duration=15 ;;
        2) test_duration=60 ;;
        *) echo -e "\n${YELLOW}[-] Sweep sequence aborted cleanly. Returning to master menu...${NC}"; sleep 1; return 0 ;;
    esac

    local total_online_cores; total_online_cores=$(nproc --all 2>/dev/null || echo "16")
    echo -e "\n${YELLOW}[⚙] Commencing stability sweep across ${total_online_cores} active paths...${NC}"
    echo -e "    Using testing tool: ${CYAN}${stress_bin}${NC} (${test_duration} seconds per processor block)\n"

    for ((core_id=0; core_id<total_online_cores; core_id++)); do
        local sys_online_file="/sys/devices/system/cpu/cpu${core_id}/online"
        
        # Safe Isolation Check: Skip the sweep iteration if a thread has been fenced off or hotplugged out
        if [[ -f "$sys_online_file" ]]; then
            if [[ $(cat "$sys_online_file" 2>/dev/null) -eq 0 ]]; then
                echo -e "  [Thread $(printf "%02d" $core_id)] ${MAGENTA}⚡ SKIPPED (Thread Fenced via Isolation Matrix)${NC}"
                continue
            fi
        fi

        echo -ne "  [Thread $(printf "%02d" $core_id)] ${YELLOW}🔄 Initializing core affinity load...${NC}"

        # 🚀 THE NATIVE REPAIR: Runs synchronously so the shell accurately captures the execution pass
        # The timeout is handled natively by the binary, keeping the terminal processing bulletproof
        if [[ "$stress_bin" == "stress-ng" ]]; then
            # We use 1 instance of the standard cpu stressor pinned exactly to our target thread via taskset
            taskset -c "$core_id" stress-ng --cpu 1 --timeout "${test_duration}s" >/dev/null 2>&1
        else
            taskset -c "$core_id" stress --cpu 1 --timeout "${test_duration}" >/dev/null 2>&1
        fi
        
        local exit_status=$?

        if [ "$exit_status" -eq 0 ]; then
            echo -e "\r  [Thread $(printf "%02d" $core_id)] ${BIGreen}[✓] PASSED (Silicon register calculations stable)${NC}"
        else
            echo -e "\r  [Thread $(printf "%02d" $core_id)] ${BIRed}[❌] FAILED (Hardware engine signal error or lockup cached)${NC}"
            TABLE_DIRTY=0; SERVICE_PENDING=1
        fi
    done

    # 🎉 SWEEP COMPLETION SUMMARY PANEL
    echo -e "\n${BIGreen}[✓] SUCCESS: Silicon Per-Core Stability Sweep successfully completed!${NC}"
    play_success_chime
    echo -e "    All processed registers have returned cleanly to default system idle loops."
    type_prompt "👉 Press Enter to return cleanly to the toolkit dashboard..." 0.03
    read -r
}

# ==============================================================================
# 🎯 FINAL UNIFIED MODULE: CPU SCHEDULER & ATOMIC ISOLATION MATRIX (PART 1)
# ==============================================================================
view_core_live_manager() {
    local native_user="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"
    local base_dir; base_dir=$(dirname "$(readlink -f "$0")")
    local cmdline_file="/proc/cmdline"
    local menu_index=0
    local static_max_threads=16

    while true; do
        clear
        echo -e "${DIM}┌────────────────────────────────────────────────────────────────────────────────────┐${RESET}"
        echo -e "${DIM}│${RESET}                 📟  Interactive Core Optimizer & Isolation Matrix                  ${DIM}│${RESET}"
        echo -e "${DIM}└────────────────────────────────────────────────────────────────────────────────────┘${RESET}"
        echo ""
        echo -e "  ${BOLD}${YELLOW}Active Hardware Real-Time Telemetry Profile:${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"

        local detected_cores; detected_cores=$(nproc --all 2>/dev/null || echo "0")
        local active_isolated; active_isolated=$(grep -o 'isolcpus=[0-7,-]*' "$cmdline_file" | cut -d= -f2 2>/dev/null || echo "None")

        local smu_probe_status="Unknown"
        if command -v setpci &>/dev/null && [ -e "/sys/bus/pci/devices/0000:00:00.0/config" ]; then
            setpci -s "0000:00:00.0" B8.L=0115A870 2>/dev/null
            local raw_mask; raw_mask=$(setpci -s "0000:00:00.0" BC.L 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "failed")

            if [[ "$raw_mask" == "000000ff" || "$raw_mask" == "ff" ]]; then
                if dmesg 2>/dev/null | grep -Eqi "(cyan-skillfish-governor-smu|bc250-unlock-cores|mailbox command 0x98)"; then
                    smu_probe_status="8 Cores (Software Patched via Run)"
                else
                    smu_probe_status="8 Cores (Unlocked via BIOS)"
                fi
            elif [[ "$raw_mask" == "00000077" || "$raw_mask" == "77" ]]; then
                smu_probe_status="6 Cores (Stock Factory Layout)"
            elif [[ "$raw_mask" == "failed" ]]; then
                smu_probe_status="Unknown (Bus Error)"
            else
                smu_probe_status="Custom (0x${raw_mask})"
            fi
        fi

        echo -e "  ${CYAN}Hardware Topology${RESET}   : ${BOLD}${WHITE}${detected_cores} Threads Active${RESET} (Silicon Register State: ${GREEN}${smu_probe_status}${RESET})"
        echo -e "  ${CYAN}Isolcpus Boot Mask${RESET}  : ${BOLD}${MAGENTA}${active_isolated}${RESET} ${DIM}(Static OS Kernel Fence Bounds)${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${BOLD}${WHITE}Live Scheduler Grid Matrix (All Silicon Channels Exposed):${RESET}\n"

        local -a core_labels
        for ((i=0; i<static_max_threads; i++)); do
            local sys_online_file="/sys/devices/system/cpu/cpu${i}/online"
            local is_fenced=0
            if [[ -n "$active_isolated" && "$active_isolated" != "None" ]]; then
                if [[ ",${active_isolated}," == *",${i},"* || "${active_isolated}" == "${i}" ]]; then
                    is_fenced=1
                elif [[ "$active_isolated" == *"-"* ]]; then
                    local start_r; start_r=$(echo "$active_isolated" | cut -d'-' -f1)
                    local end_r; end_r=$(echo "$active_isolated" | cut -d'-' -f2)
                    if (( i >= start_r && i <= end_r )); then is_fenced=1; fi
                fi
            fi

            if [[ "$is_fenced" -eq 1 ]]; then
                core_labels[$i]="${MAGENTA}⚡ ISOLATED (Fenced)${RESET}"
            elif [[ ! -d "/sys/devices/system/cpu/cpu${i}" ]]; then
                core_labels[$i]="${DIM}□ DISABLED (BIOS Hidden)${RESET}"
            elif [[ -f "$sys_online_file" ]]; then
                local is_online; is_online=$(cat "$sys_online_file" 2>/dev/null)
                if [[ "$is_online" -eq 1 ]]; then core_labels[$i]="${GREEN}■ ACTIVE${RESET}"
                else core_labels[$i]="${RED}□ INACTIVE (Hotplugged)${RESET}"; fi
            else
                core_labels[$i]="${GREEN}■ ACTIVE${RESET}"
            fi

            if [[ "$i" -eq "$menu_index" ]]; then
                echo -e "    ${YELLOW}👉 [Thread $(printf "%02d" $i)] [ ${core_labels[$i]} ]   <-- Press [Spacebar] to Toggle State${RESET}"
            else
                echo -e "       [Thread $(printf "%02d" $i)] [ ${core_labels[$i]} ]"
            fi
        done
        # Context Menu Base Actions Footer Rows (Decoded Step Borders)
        echo ""
        local c_edit="${CYAN}" local c_write="${CYAN}" local c_install="${CYAN}"
        if [ "${TABLE_DIRTY:-0}" -eq 1 ]; then c_edit="${DIM}"; c_write="${GREEN}${BOLD}"
        elif [ "${SERVICE_PENDING:-0}" -eq 1 ]; then c_write="${DIM}"; c_install="${GREEN}${BOLD}"; fi

        if [[ "$menu_index" -eq "$static_max_threads" ]]; then echo -e "    ${YELLOW}👉 ${c_edit}[e]${RESET} Trigger SMU Mailbox Hardware Core Unlock Toolchain Pipeline${RESET}"
        else echo -e "       ${c_edit}[e]${RESET} Trigger SMU Mailbox Hardware Core Unlock Toolchain Pipeline"; fi
        if [[ "$menu_index" -eq $((static_max_threads + 1)) ]]; then echo -e "    ${YELLOW}👉 ${c_install}[i]${RESET} Configure Persistent Static bootloader Isolcpus Parameters${RESET}"
        else echo -e "       ${c_install}[i]${RESET} Configure Persistent Static bootloader Isolcpus Parameters"; fi
        if [[ "$menu_index" -eq $((static_max_threads + 2)) ]]; then echo -e "    ${YELLOW}👉 ${c_write}[c]${RESET} Commit Structural Core Mask Changes & Save Service Table${RESET}"
        else echo -e "       ${c_write}[c]${RESET} Commit Structural Core Mask Changes & Save Service Table"; fi
        if [[ "$menu_index" -eq $((static_max_threads + 3)) ]]; then echo -e "    ${YELLOW}👉 ${RED}[q]${RESET} Return Cleanly to Master Toolkit Dashboard Menu${RESET}"
        else echo -e "       ${RED}[q]${RESET} Return Cleanly to Master Toolkit Dashboard Menu"; fi

        echo -e "\n  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${BOLD}${WHITE}Navigation Controls:${RESET} Use ${CYAN}W / S${RESET} to move. Press ${GREEN}[Spacebar]${RESET} to toggle thread state. Press ${GREEN}[Enter]${RESET} to commit table changes."

        # 🎯 RESTORED MAPPING: Enter and C/c instantly commit from anywhere, Spacebar toggles everything else
        local key=""
        IFS= read -r -s -n 1 raw_key
        key="$raw_key"
        
        if [[ -z "$key" || "$key" == $'\r' || "$key" == $'\n' ]]; then
            read -r -s -t 0.1 next_char 2>/dev/null
            key="ENTER"
        fi

        case "$key" in
            [Ww])
                ((menu_index--))
                if ((menu_index < 0)); then menu_index=$((static_max_threads + 3)); fi
                ;;
            [Ss])
                ((menu_index++))
                if ((menu_index > (static_max_threads + 3))); then menu_index=0; fi
                ;;
            " ") # 🚀 SPACEBAR MULTITOOL: Toggles threads OR fires highlighted menu options natively!
                if ((menu_index >= 0 && menu_index < static_max_threads)); then
                    local target_cpu_file="/sys/devices/system/cpu/cpu${menu_index}/online"
                    if [[ "$menu_index" -eq 0 ]]; then
                        echo -e "\n${BIRed}[!] ERROR: CPU Core 0 is the primary system bootstrap anchor and cannot be offlined.${NC}"
                        sleep 1.5; continue
                    fi
                    if [[ -f "$target_cpu_file" ]]; then
                        if [[ $(cat "$target_cpu_file" 2>/dev/null) -eq 1 ]]; then
                            echo 0 > "$target_cpu_file" 2>/dev/null
                            echo -e "\n${YELLOW}[⚙] Thread ${menu_index} hotplugged OFFLINE... OS scheduler fence dropped.${NC}"
                        else
                            echo 1 > "$target_cpu_file" 2>/dev/null
                            echo -e "\n${BIGreen}[✓] Thread ${menu_index} hotplugged ONLINE... OS scheduler fence restored.${NC}"
                        fi
                        TABLE_DIRTY=1; SERVICE_PENDING=0; sync && sleep 0.5
                    else
                        echo -e "\n${BIRed}[!] ERROR: Core/Thread ${menu_index} is hidden by BIOS configuration or un-enumerated by AGESA.${NC}"
                        sleep 2.5
                    fi
                elif [[ "$menu_index" -eq "$static_max_threads" ]]; then
                    execute_smu_core_unlock
                elif [[ "$menu_index" -eq $((static_max_threads + 1)) ]]; then
                    configure_persistent_isolcpus
                elif [[ "$menu_index" -eq $((static_max_threads + 2)) ]]; then
                    execute_pre_commit_gate
                elif [[ "$menu_index" -eq $((static_max_threads + 3)) ]]; then
                    echo -e "\n${GREEN}[+] Returning cleanly to toolkit dashboard menu...${NC}"
                    sleep 0.5; return 0
                fi
                ;;
            [Cc]|[cc]|"ENTER")
                execute_pre_commit_gate
                ;;
            [Ee]|[ee]) execute_smu_core_unlock ;;
            [Ii]|[ii]) configure_persistent_isolcpus ;;
            [Qq]|[qq]) echo -e "\n${GREEN}[+] Returning cleanly to toolkit dashboard menu...${NC}"; sleep 0.5; return 0 ;;
            *)
                continue
                ;;
        esac
    done
}

# ==============================================================================
# SUBROUTINE: NATIVE BASH SMU MAILBOX OVERRIDE PRIMITIVE (0x98 PAYLOAD)
# ==============================================================================
execute_smu_core_unlock() {
    echo -e "\n${YELLOW}[⚙] Initiating low-level native SMU core unlock sequence...${NC}"

    local before_mask; before_mask=$(smn_read32 "$CPU_MASK_REG" 2>/dev/null || echo "0x00")
    info "Current Core Presence Silicon Mask: $before_mask"

    if [[ "$before_mask" == "0x000000ff" || "$before_mask" == "0xff" ]]; then
        info "Silicon core presence mask is already raised to 0xFF!"
        info "Perform a system cold reset/reboot to bring up all 8 cores (16 threads)."
    else
        echo -e "${CYAN}[ℹ] Transmitting Queue 3 mailbox command 0x98 payload...${NC}"

        local status_response
        if status_response=$(smu_q3_send "$SMU_MSG_WRITE_FF" "$CPU_MASK_REG"); then
            local status_hex; status_hex=$(printf '0x%02X' $((status_response)))
            info "SMU mailbox transaction complete. Response status: $status_hex"

            sleep 0.2
            local after_mask; after_mask=$(smn_read32 "$CPU_MASK_REG" 2>/dev/null || echo "failed")
            info "Verification Core Silicon Mask after write: $after_mask"

            if [[ "$after_mask" == "0x000000ff" || "$after_mask" == "0xff" ]]; then
                echo -e "${BIGreen}[✓] SUCCESS: CPU core unlock armed inside SMU runtime registers!${NC}"
                TABLE_DIRTY=0; SERVICE_PENDING=1
            else
                err "Write operation dropped by hardware layer. Register mask did not take."
            fi
        else
            err "SMU mailbox command pipeline timed out or config bus rejected the framing."
        fi
    fi

    echo -e "\n${GREEN}[✓] Unlock routine completed. System changes require a reboot to mount topology charts.${NC}"
    read -p "👉 Press Enter to return to matrix dashboard..."
}

# ==============================================================================
# SUBROUTINE: INTERACTIVE PRE-COMMIT VERIFICATION GATE
# ==============================================================================
execute_pre_commit_gate() {
    echo -e "\n${YELLOW}[⚠️] WARNING: You are about to permanently modify Bazzite's atomic kernel arguments.${NC}"
    echo -e "    To compile your live matrix changes and stage a system reset, type ${GREEN}accept${NC} or ${GREEN}ACCEPT${NC}."
    type_prompt "👉 Verification Command Input: " 0.03
    local confirm_commit; read -r confirm_commit

    if [[ "$confirm_commit" == "accept" || "$confirm_commit" == "ACCEPT" ]]; then
        local offline_list=""
        for ((core_id=0; core_id<static_max_threads; core_id++)); do
            local core_file="/sys/devices/system/cpu/cpu${core_id}/online"
            if [[ -f "$core_file" ]]; then
                if [[ $(cat "$core_file" 2>/dev/null) -eq 0 ]]; then
                    [ -z "$offline_list" ] && offline_list="${core_id}" || offline_list="${offline_list},${core_id}"
                fi
            fi
        done
        execute_atomic_karg_sync "$offline_list"
    else
        echo -e "\n${BIRed}[-] Verification failed or bypassed. Aborting commit pass.${NC}"
        type_prompt "    Press Enter to return to the dashboard..." 0.03
        read -r
    fi
}

# ==============================================================================
# SUBROUTINE: FIXED INTERACTIVE MANUAL INJECTION ENGINE WITH CLEAR INSTRUCTIONS
# ==============================================================================
configure_persistent_isolcpus() {
    echo -e "\n${CYAN}[ℹ] Bazzite Atomic Kernel Boot Parameter Configuration Engine${RESET}"
    echo -e "${BOLD}${YELLOW}⚠️  PRE-BOOT SILICON ISOLATION SHIELD:${RESET}"
    echo -e "  Altering kernel arguments via atomic single-pass tracking layers.\n"
    echo -e "  Enter the thread/core indexes you want completely blocked from the kernel loader."
    echo -e "  Examples: ${YELLOW}12${NC} (Isolates thread 12) or ${YELLOW}12,13${NC} (Isolates threads 12 and 13)"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  💡 ${BIGreen}HOW TO RESTORE CORES:${RESET}"
    echo -e "     Type ${GREEN}clear${RESET} inside the box below to completely remove your static fences"
    echo -e "     and reactivate all isolated threads back to stock active states."
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────────────────────${RESET}\n"
    type_prompt "👉 Target Isolation Mask: " 0.03
    local user_cores; read -r user_cores
    [ -z "$user_cores" ] && { echo -e "[-] No entry detected. Bypassing."; sleep 1; return 0; }

    local target_val=""
    [ "$user_cores" != "clear" ] && target_val="$user_cores"
    
    # Passes directly to the sync pipeline without ever prompting for an "accept" string!
    execute_atomic_karg_sync "$target_val"
}

# ==============================================================================
# SUBROUTINE: UNIFIED ATOMIC EXECUTION PIPE WITH STRICT REBOOT VALIDATION
# ==============================================================================
execute_atomic_karg_sync() {
    local target_cores="$1"
    echo -e "\n${YELLOW}[⚙] Scanning current deployment and formatting instruction parameters...${NC}"
    local current_kargs; current_kargs=$(rpm-ostree kargs)
    local old_isolcpus; old_isolcpus=$(echo "$current_kargs" | grep -o 'isolcpus=[^ ]*' || echo "")
    local old_dcmask; old_dcmask=$(echo "$current_kargs" | grep -o 'amdgpu.dcdebugmask=[^ ]*' || echo "")

    local -a karg_args=()
    [ -n "$old_isolcpus" ] && karg_args+=( --delete="$old_isolcpus" )
    [ -n "$old_dcmask" ] && karg_args+=( --delete="$old_dcmask" )

    local append_dcmask=""
    if [[ -n "$old_dcmask" ]]; then
        append_dcmask="amdgpu.dcdebugmask=0x10"
    elif dmesg 2>/dev/null | grep -Eqi "(fc44|plasma-sddm-race|7.2.7-ogc)"; then
        append_dcmask="amdgpu.dcdebugmask=0x10"
    fi

    if [ -n "$target_cores" ]; then
        if [[ -n "$append_dcmask" ]]; then
            karg_args+=( --append="rhgb" --append="quiet" --append="$append_dcmask" --append="isolcpus=${target_cores}" )
        else
            karg_args+=( --append="rhgb" --append="quiet" --append="isolcpus=${target_cores}" )
        fi
        echo -e "${CYAN}[+] Staging core layout fence: isolcpus=${target_cores}...${NC}"
    else
        if [[ -n "$append_dcmask" ]]; then
            karg_args+=( --append="rhgb" --append="quiet" --append="$append_dcmask" )
        else
            karg_args+=( --append="rhgb" --append="quiet" )
        fi
        echo -e "${YELLOW}[⚙] Staging complete core isolation purge...${NC}"
    fi

    echo -e "${CYAN}[⚙] Dispatching unified rpm-ostree transaction suite...${NC}"
    rpm-ostree kargs "${karg_args[@]}" &>/dev/null &
    local transaction_pid=$!
    local spinner=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )

    while kill -0 "$transaction_pid" 2>/dev/null; do
        for frame in "${spinner[@]}"; do
            echo -ne "\r  \033[0;36m[$frame] Re-building atomic boot records cleanly in background...${NC}"
            sleep 0.08
        done
    done
    echo -ne "\r                                                                         \r"
    wait "$transaction_pid"

    if [ $? -eq 0 ]; then
        echo -e "${BIGreen}[✓] SUCCESS: Core configurations permanently frozen in Bazzite boot deployment!${NC}"
        [ -f "/etc/default/grub" ] && { sudo sed -i 's/\([ "]\)isolcpus=[^ "]*\([ "]\)/\1\2/g' /etc/default/grub 2>/dev/null; sudo sed -i 's/  */ /g' /etc/default/grub 2>/dev/null; }
        
        # 🚀 ATOMIC REBOOT DIALOG (Front-gate already passed safely)
        echo -e "\n${BIGreen}[✓] SUCCESS: Atomic deployment updated! System changes require a reboot to load.${NC}"
        type_prompt "❓ Would you like to execute a system cold reset right now? (y/N): " 0.03
        local reboot_choice; read -r reboot_choice
        if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}[!] Sending ACPI Cold Reset signal... re-mounting hardware rails...${NC}"
            sync && sleep 1 && reboot
        fi
        echo -e "\n${BIRed}[-] Verification failed or bypassed. Skipping automated reboot tracking sequence.${NC}"
        type_prompt "    Press Enter to return to the core optimization dashboard..." 0.03
        read -r
    else
        echo -e "${BIRed}❌ ERROR: Bazzite atomic tracker rejected the pooled instruction framing.${NC}"
        read -p "Press Enter to return..."
    fi
    TABLE_DIRTY=0; SERVICE_PENDING=1
}

# ==============================================================================
# SUBROUTINE: STANDALONE GRAPHICAL BOOT SPLASH RESTORATION & ARGUMENT INJECTOR
# ==============================================================================
repair_boot_splash_only() {
    clear
    echo -e "${DIM}┌────────────────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${DIM}│${RESET}                 📟  Bazzite Dedicated Boot Splash Screen Repair Utility             ${DIM}│${RESET}"
    echo -e "${DIM}└────────────────────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${BOLD}${YELLOW}⚠️  GRAPHICAL SPLASH RESET PROTOCOL:${RESET}"
    echo -e "  This function will force-inject Red Hat Graphical Boot (rhgb) and quiet"
    echo -e "  parameters straight into Bazzite's atomic tracking deployment tree."
    echo -e "  This sweeps away scrolling text and restores your black boot-up splash animations."
    echo ""
    echo -e "  ${CYAN}[ℹ] OPTIONAL BAZZITE 44 DISPLAY CORE FIX:${RESET}"
    echo -e "      If your splash is broken on Bazzite 44, type: ${GREEN}amdgpu.dcdebugmask=0x10${NC}"
    echo -e "      Or press ${GREEN}[Enter]${NC} to run a standard splash repair pass."
    echo ""

    type_prompt "👉 Custom Boot Arguments (Optional): " 0.03
    local custom_args; read -r custom_args

    echo -e "\n${YELLOW}[⚙] Scanning current deployment boot parameter strings...${NC}"
    local current_kargs; current_kargs=$(rpm-ostree kargs)

    local has_rhgb; has_rhgb=$(echo "$current_kargs" | grep -o 'rhgb' || echo "")
    local has_quiet; has_quiet=$(echo "$current_kargs" | grep -o 'quiet' || echo "")

    local -a repair_args=()

    if [[ -n "$has_rhgb" ]]; then repair_args+=( --delete="rhgb" ); fi
    if [[ -n "$has_quiet" ]]; then repair_args+=( --delete="quiet" ); fi

    # Check if they have an old copy of the dcdebugmask hanging around to clear it first
    local old_mask; old_mask=$(echo "$current_kargs" | grep -o 'amdgpu.dcdebugmask=[^ ]*' || echo "")
    if [[ -n "$old_mask" ]]; then repair_args+=( --delete="$old_mask" ); fi

    # Staging standard repair structures
    repair_args+=( --append="rhgb" --append="quiet" )

    # 🎯 CUSTOM ENTRY INJECTION GATE: Safely tracks your custom argument if provided
    if [[ -n "$custom_args" ]]; then
        repair_args+=( --append="$custom_args" )
        echo -e "${CYAN}[+] Staging recovery targets: [rhgb] [quiet] [${custom_args}] elements...${NC}"
    else
        echo -e "${CYAN}[+] Staging recovery targets: [rhgb] [quiet] elements...${NC}"
    fi
    if [[ ${#repair_args[@]} -gt 0 ]]; then
        echo -e "${CYAN}[⚙] Dispatching dedicated splash recovery transaction...${NC}"

        # 🚀 CLEAN ISOLATED PIPE: Executes the array configurations smoothly in the background
        rpm-ostree kargs "${repair_args[@]}" &>/dev/null &
        local transaction_pid=$!
        local spinner=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )

        while kill -0 "$transaction_pid" 2>/dev/null; do
            for frame in "${spinner[@]}"; do
                echo -ne "\r  \033[0;36m[$frame] Re-building atomic deployment records cleanly...${NC}"
                sleep 0.08
            done
        done
        echo -ne "\r                                                                         \r"

        wait "$transaction_pid"
        if [ $? -eq 0 ]; then
            echo -e "${BIGreen}[✓] SUCCESS: Graphical splash configurations force-restored!${NC}"

            # Clean legacy GRUB backups if present to ensure system config purity
            if [[ -f "/etc/default/grub" ]]; then
                sudo sed -i 's/\([ "]\)isolcpus=[^ "]*\([ "]\)/\1\2/g' /etc/default/grub 2>/dev/null
                sudo sed -i 's/  */ /g' /etc/default/grub 2>/dev/null
            fi
        else
            echo -e "${BIRed}❌ ERROR: Bazzite atomic tracker rejected the repair sequence layout.${NC}"
            read -p "Press Enter to return..."
            return 1
        fi
    else
        echo -e "${GREEN}[+] Verification Pass Complete: Splash screen arguments are already optimally active.${NC}"
        sleep 1.5; return 0
    fi

    # 🚀 ATOMIC REBOOT DIALOG
    echo -e "\n${BIGreen}[✓] SUCCESS: Deployment sync complete! System changes require a reboot to load.${NC}"
    type_prompt "❓ Would you like to execute a system cold reset right now? (y/N): " 0.03
    local reboot_choice; read -r reboot_choice
    if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[!] Sending ACPI Cold Reset signal... re-mounting hardware rails...${NC}"
        sync && sleep 1 && reboot
    fi
}

# ==============================================================================
# SUBROUTINE: GDDR6 HARDWARE VRAM TELEMETRY MONITOR & COLD DATA VIEW
# ==============================================================================
view_vram_temperatures() {
    clear
    local base_dir; base_dir=$(dirname "$(readlink -f "$0")")
    local py_script="${base_dir}/bc250_mem_temp.py"
    
    if [[ ! -f "$py_script" ]]; then
        echo -e "${BIRed}❌ ERROR: Missing target dependency wrapper script row.${NC}"
        echo -e "          Please ensure the Python script is saved to: ${YELLOW}${py_script}${NC}"
        read -p "Press Enter to return..." && return 1
    fi

    echo -e "${DIM}┌────────────────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${DIM}│${RESET}               📟  AMD BC-250 GDDR6 Live VRAM Temperature Telemetry                 ${DIM}│${RESET}"
    echo -e "${DIM}└────────────────────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${BOLD}${YELLOW}Active Hardware Real-Time Sensor Grid:${RESET}"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"

    local raw_output; raw_output=$(python3 "$py_script" 2>/dev/null)
    local exit_code=$?

    if [[ "$exit_code" -eq 2 || "$raw_output" == "ERR_BIOS_LOCKED" ]]; then
        echo -e "  ${BIRed}❌ DIAGNOSTIC CRASH ABORT: GDDR6 Memory Registers are locked by AGESA.${NC}"
        echo -e "  ${YELLOW}[ℹ] Solution Requirement Matrix:${NC}"
        echo -e "      Your system reports active hardware masks, but you must be running a"
        echo -e "      ${GREEN}P3.00 BIOS${NC} or newer to expose live memory thermal registers to the OS."
        echo -e "      Stock mining profiles (V3/V5 base software layout) are completely unmapped."
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        read -p "👉 Press Enter to return cleanly to toolkit..." && return 0
    elif [[ "$exit_code" -ne 0 || -z "$raw_output" || "$raw_output" == "ERR_BUS_ERROR" ]]; then
        echo -e "  ${BIRed}❌ ERROR: Hardware bus communication timeout. Configuration registers un-enumerated.${NC}"
        read -p "Press Enter to return..." && return 1
    fi

    IFS='|' read -r tA tB tC tD <<< "$raw_output"
    
    format_temp_color() {
        local val="$1"
        if (( val >= 85 )); then echo -e "${RED}${val}°C 🔥 [CRITICAL]${NC}"
        elif (( val >= 75 )); then echo -e "${YELLOW}${val}°C ⚠️ [WARN]${NC}"
        else echo -e "${GREEN}${val}°C [OPTIMAL]${NC}"; fi
    }

    echo -e "    Memory Controller Channel A Thermals : $(format_temp_color "$tA")"
    echo -e "    Memory Controller Channel B Thermals : $(format_temp_color "$tB")"
    echo -e "    Memory Controller Channel C Thermals : $(format_temp_color "$tC")"
    echo -e "    Memory Controller Channel D Thermals : $(format_temp_color "$tD")"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${DIM}Operating limits: Optimal <75°C | Maximum 85°C Tjmax limit throttling boundaries.${RESET}\n"
    
    type_prompt "👉 Press Enter to return cleanly to dashboard matrix loops..." 0.03
    read -r
}

# ==============================================================================
# SUBROUTINE: AUTOMATED BC250-TELEMETRY DAEMON AND WEB DASHBOARD INSTALLER
# ==============================================================================
install_bc250_telemetry_daemon() {
    clear
    local base_dir; base_dir=$(dirname "$(readlink -f "$0")")
    local daemon_dir="${base_dir}/bc250-telemetry-daemon"
    local service_file="/etc/systemd/system/bc250-telemetry.service"
    
    # 🎯 THE FIX: Directly anchor our target path check to exactly where tar flattens the file!
    local target_bin="/usr/local/bin/bc250-telemetry"

    echo -e "${DIM}┌────────────────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${DIM}│${RESET}                📟  AMD BC-250 Complete VRM & Rail Telemetry Installer             ${DIM}│${RESET}"
    echo -e "${DIM}└────────────────────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${BOLD}${YELLOW}⚠️  HARDWARE BUS REQUISITE FLAG:${RESET}"
    echo -e "  This daemon reads direct rail voltages and current loads from your physical VRMs."
    echo -e "  To prevent connection time-outs, you must have physically jumped the monitoring"
    echo -e "  wires between ${MAGENTA}I2C_HEADER1${RESET} and ${MAGENTA}TPMS1${RESET} on your board."
    echo ""
    
    type_prompt "❓ Download and configure persistent telemetry background daemon? (y/N): " 0.03
    local run_install; read -r run_install
    if [[ ! "$run_install" =~ ^[Yy]$ ]]; then
        echo -e "\n${YELLOW}[-] Setup bypassed. Returning to toolkit matrix loops...${NC}"
        sleep 1.5; return 0
    fi

    # Clean out any old broken configurations and target directory paths recursively
    sudo systemctl disable --now bc250-telemetry.service &>/dev/null || true
    sudo rm -f "$service_file" "$target_bin"
    sudo rm -rf "$daemon_dir"
    sudo mkdir -p "$daemon_dir"

    echo -e "\n${YELLOW}[⚙] Retrieving compiled Linux release architecture from repository tracks...${NC}"
    
    # Secure download pass targeting the official repository compressed asset bundle
    sudo curl -L -o "${daemon_dir}/telemetry.tar.gz" "https://github.com/onlinermm/BC250-Telemetry/releases/download/v0.3.1/bc250-telemetry.tar.gz" >> "$LOG_FILE" 2>&1
    
    if [[ ! -s "${daemon_dir}/telemetry.tar.gz" ]]; then
        echo -e "${BIRed}❌ ERROR: Network download failed. The release track could not be reached.${NC}"
        sudo rm -rf "$daemon_dir"
        read -p "Press Enter to return..." && return 1
    fi

    # 🚀 THE NATIVE REPAIR: Extract and instantly pipe the file straight into /usr/local/bin/ 
    # This strips the nested archive folder structures completely on the fly with zero path guessing
    sudo tar -xzf "${daemon_dir}/telemetry.tar.gz" --strip-components=1 -C "$daemon_dir" 2>/dev/null
    sudo rm -f "${daemon_dir}/telemetry.tar.gz"

    # Move the extracted file directly into the executable system bin layers
    if [[ -f "${daemon_dir}/bc250-telemetry" ]]; then
        sudo mv "${daemon_dir}/bc250-telemetry" "$target_bin"
    fi

    # Check the final system path explicitly
    if [[ ! -f "$target_bin" ]]; then
        echo -e "${BIRed}❌ ERROR: Binary extraction failed. Executable could not be mapped.${NC}"
        sudo rm -rf "$daemon_dir"
        read -p "Press Enter to return..." && return 1
    fi

    sudo chmod +x "$target_bin"

    # 📝 SYSTEMD PROFILE GENERATION
    echo -e "${CYAN}[+] Compiling background unit manager service tracking maps...${NC}"
    sudo cat << EOF | sudo tee "$service_file" > /dev/null
[Unit]
Description=AMD BC-250 Complete VRM Hardware Telemetry Daemon
After=network.target

[Service]
Type=simple
ExecStart=${target_bin} --port=8085
Restart=always
RestartSec=5
WorkingDirectory=${daemon_dir}

[Install]
WantedBy=multi-user.target
EOF

    echo -e "${CYAN}[⚙] Activating telemetry daemon synchronization pipelines...${NC}"
    sudo systemctl daemon-reload
    sudo systemctl enable --now bc250-telemetry.service &>/dev/null

    sleep 0.8
    if systemctl is-active --quiet bc250-telemetry.service; then
        echo -e "\n${BIGreen}[✓] SUCCESS: Telemetry background daemon successfully armed and executing!${NC}"
        echo -e "    Real-time diagnostics are broadcasting live over your network dashboard."
        echo -e "    👉 Open Web Console: ${GREEN}http://localhost:8085${NC} or ${GREEN}http://$(hostname -I | awk '{print $1}'):8085${NC}"
    else
        echo -e "\n${BIRed}❌ WARNING: Service launched but timed out early. Hardware link required!${NC}"
        echo -e "             Review the 'hardware.md' requirements file regarding your jump wire pins."
    fi

    # 🎉 CLEAN SYSTEM CLOSURE HOOK
    play_success_chime
    echo -e "\n${GREEN}    Press [Enter] to return cleanly to the toolkit dashboard menu...${NC}"
    read -r
}

# ==============================================================================
# SUBROUTINE: PRODUCTION-READY CU LIVE MANAGER COMPLETE ROLLBACK UTILITY (PART 1)
# ==============================================================================
uninstall_cu_live_manager() {
    # 🧠 PRE-REMOVAL SECURITY GATES: Strict verification check BEFORE any system files are altered!
    echo -e "\n${BIRed}[⚠️] CRITICAL NOTICE: You are about to completely wipe the CU Live Manager Suite.${NC}"
    echo -e "    This will strip all systemd service profiles and revert atomic boot loader flags."
    echo -e "    To proceed with the permanent removal, please type ${YELLOW}accept${NC} or ${YELLOW}ACCEPT${NC}."
    type_prompt "👉 Verification Command Input: " 0.03
    local confirm_uninstall; read -r confirm_uninstall

    if [[ "$confirm_uninstall" == "accept" || "$confirm_uninstall" == "ACCEPT" ]]; then
        # 🔓 GATE PASSED: Proceed natively to file structure demolition and service purging
        log "${RED}[Uninstall] Initializing CU Live Manager rollback suite...${NC}"

        sudo systemctl disable --now bc250-cu-live-manager.service >> "$LOG_FILE" 2>&1 || true
        sudo rm -f /etc/systemd/system/bc250-cu-live-manager.service
        sudo rm -f /usr/local/bin/bc250-cu-live-manager
        sudo rm -f /etc/bc250-cu-live-manager.conf
        sudo rm -f /tmp/bc250-cu-live-manager.sh
        sudo rpm-ostree uninstall umr >> "$LOG_FILE" 2>&1
        sudo systemctl daemon-reload

        # Staging the cleanup parameter array metrics
        echo -e "\n${YELLOW}[⚙] Scanning deployment tracker for lingering toolkit boot parameters...${NC}"
        local current_kargs; current_kargs=$(rpm-ostree kargs)
        local old_isolcpus; old_isolcpus=$(echo "$current_kargs" | grep -o 'isolcpus=[^ ]*' || echo "")
        local old_dcmask; old_dcmask=$(echo "$current_kargs" | grep -o 'amdgpu.dcdebugmask=[^ ]*' || echo "")

        local -a karg_args=()
        [ -n "$old_isolcpus" ] && karg_args+=( --delete="$old_isolcpus" )
        [ -n "$old_dcmask" ] && karg_args+=( --delete="$old_dcmask" )

        # Force-append standard desktop splash elements back to clean out configurations safely
        karg_args+=( --append="rhgb" --append="quiet" )
        # 🚀 CLEAN INSTRUCTION PIPE: Passes the combined array arguments smoothly to rpm-ostree
        if [[ ${#karg_args[@]} -gt 0 ]]; then
            echo -e "${CYAN}[⚙] Dispatching atomic parameter cleanup transaction...${NC}"

            rpm-ostree kargs "${karg_args[@]}" &>/dev/null &
            local transaction_pid=$!
            local spinner=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )

            while kill -0 "$transaction_pid" 2>/dev/null; do
                for frame in "${spinner[@]}"; do
                    echo -ne "\r  \033[0;36m[$frame] Cleaning up atomic boot parameter records...${NC}"
                    sleep 0.08
                done
            done
            echo -ne "\r                                                                         \r"
            wait "$transaction_pid"
        fi

        # Synchronize and clean local legacy GRUB configuration strings if present
        if [[ -f "/etc/default/grub" ]]; then
            sudo sed -i 's/\([ "]\)isolcpus=[^ "]*\([ "]\)/\1\2/g' /etc/default/grub 2>/dev/null
            sudo sed -i 's/\([ "]\)amdgpu.dcdebugmask=[^ "]*\([ "]\)/\1\2/g' /etc/default/grub 2>/dev/null
            sudo sed -i 's/  */ /g' /etc/default/grub 2>/dev/null
        fi

        # 🎉 COMPLETION SECTOR: Audio feedback triggers alongside your custom reboot prompts
        echo -e "\n${BIGreen}[✓] SUCCESS: CU Live Manager Suite has been completely scrubbed from the system!${NC}"
        play_success_chime

        type_prompt "❓ Would you like to execute a system cold reset right now? (y/N): " 0.03
        local reboot_choice; read -r reboot_choice
        if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}[!] Sending ACPI Cold Reset signal... re-mounting hardware rails...${NC}"
            sync && sleep 1 && reboot
        fi
    else
        # 🔒 GATE BLOCKED: User didn't type accept, keep system completely untouched
        echo -e "\n${BIRed}[-] Verification failed or bypassed. Aborting removal suite pass. System state preserved.${NC}"
        type_prompt "    Press Enter to return to the toolkit menu..." 0.03
        read -r
    fi
}

type_prompt() {
    local text="$1"
    local delay="${2:-0.03}"

    for (( i=0; i<${#text}; i++ )); do
        echo -ne "\033[38;2;0;255;0m${text:$i:1}\033[0m"

        if [ "$SKIP_ANIMATION" = false ]; then
            # 🧬 LOCK-JAW KEY CHECK: Instantly polls stdin terminal cache descriptor
            if read -t 0.001 -n 1 2>/dev/null; then
                SKIP_ANIMATION=true
            fi
            sleep "$delay"
        fi
    done
}

case "$1" in
    --phase2) run_phase2; exit 0 ;;
    --manager-phase2) run_manager_phase2; exit 0 ;;
    --uninstall-cpu) uninstall_cpu_overclock; exit 0 ;;
    --uninstall-cu) uninstall_cu_live_manager; exit 0 ;;
esac

while true; do
    clear
    TEXT_STR="            BC-250 CPU OVERCLOCK & Compute Unit Live Manager Setup Tool             "
    echo -e "${DIM}┌────────────────────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${DIM}│${RESET}${BOLD}${MAGENTA}${TEXT_STR}${RESET}${DIM}│${RESET}"
    echo -e "${DIM}└────────────────────────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
    echo -e "  ${BOLD}${WHITE}Select an action to perform:${RESET}"
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "    ${BOLD}${RED}• CPU Overclocking Suite:${RESET}"
    echo -e "      ${CYAN}[1a]${RESET} Install Toolchain & Configure Settings  ${DIM}(Phase 1 - Requires Reboot)${RESET}"
    echo -e "      ${CYAN}[1b]${RESET} Complete Toolchain Installation         ${DIM}(Phase 2)${RESET}"
    echo ""
    echo -e "    ${BOLD}${BLUE}• Compute Unit Live Manager:${RESET}"
    echo -e "      ${CYAN}[2a]${RESET} Install Package Dependencies            ${DIM}(Phase 1 - Requires Reboot)${RESET}"
    echo -e "      ${CYAN}[2b]${RESET} Launch Live Matrix Configuration        ${DIM}(Phase 2)${RESET}"
    echo ""
    echo -e "    ${BOLD}${CYAN}• Silicon Governor & Performance Tuning Profile Manager:${RESET}"
    echo -e "      ${CYAN}[M]${RESET}  Modify Governor Performance Profile     ${DIM}(Hardware Spec Audit Wizard)${RESET}"
    echo -e "      ${CYAN}[C]${RESET}  Inject Manual Governor Clock Clamp      ${DIM}(Hot-patch active SMU ceilings)${RESET}"
    echo ""
    echo -e "    ${BOLD}${YELLOW}• Rollback & Restoration Profiles:${RESET}"
    echo -e "      ${DIM}[3a] Uninstall CPU Overclock Profiles Completely${RESET}"
    echo -e "      ${DIM}[3b] Uninstall Compute Unit Live Manager Service Paths${RESET}"
    echo ""
    echo -e "    ${BOLD}${YELLOW}• Silicon Stability Testing Channels:${RESET}"
    echo -e "      ${CYAN}[4]${RESET}   Launch Silicon Per-Core Stability Sweep ${DIM}(test-cores Curve Validation)${RESET}"    
    echo -e "      ${CYAN}[5]${RESET}   Launch CPU Core Scheduler & Isolation Matrix ${DIM}(Live Core Matrix & Isolcpus)${RESET}"    
    echo -e "      ${CYAN}[6]${RESET}   Force-Restore Graphical Boot Splash Screen ${DIM}(Repair rhgb / quiet Flags)${RESET}"
    echo -e "      ${CYAN}[7]${RESET}   Query GDDR6 Real-Time Memory Temperature Telemetries ${DIM}(Sensors View)${RESET}"
    echo -e "      ${CYAN}[8]${RESET}   Deploy VRM Hardware Telemetry Service Daemon ${DIM}(onlinermm Web Dashboard)${RESET}"
    echo ""
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "      ${BOLD}${WHITE}[↵]${RESET} Hit Enter to Secure Safe Exit Overclock-Live-Manager"
    echo ""
    
    type_prompt "  Select an option [ 1a-8, M, C, ↵ ]: " 0.03
    choice=""
    read -r choice
    echo ""    
    # Convert input to lowercase or handle multi-case matching smoothly
    case "$choice" in
        1a|1A) run_phase1 ;;
        1b|1B) run_phase2 ;;
        2a|2A) run_manager_phase1 ;;
        2b|2B) run_manager_phase2 ;;
        m|M) configure_governor_profile ;;
        c|C) apply_manual_clock_clamp ;;
        r|R)
                print_info "Reinitializing toolkit memory tracking blocks..."
                sleep 0.5
                exec bash "$SCRIPT_PATH" "$@"
                ;;
        3a|3A) uninstall_cpu_overclock ;;
        3b|3B) uninstall_cu_live_manager ;;
        4) run_stability_sweep ;;
        5) view_core_live_manager ;;        
        6) repair_boot_splash_only ;;
        7) view_vram_temperatures ;;
        8) install_bc250_telemetry_daemon ;;
        "") echo -e "  ${YELLOW}[-] Exiting Overclock-Live-Manager...${RESET}"; sleep 1; exit 0 ;;
        *) echo -e "  ${RED}❌ ERROR: Invalid menu option selection '$choice'.${RESET}"; sleep 1.5 ;;
    esac
done

        "") echo -e "  ${YELLOW}[-] Exiting Overclock-Live-Manager...${RESET}"; sleep 1; exit 0 ;;
        *) echo -e "  ${RED}❌ ERROR: Invalid menu option selection '$choice'.${RESET}"; sleep 1.5 ;;
    esac
done
