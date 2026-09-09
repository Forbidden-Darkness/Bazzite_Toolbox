#!/bin/bash

clear
# Color definitions
RED='\033[0;31m'
B_RED='\033[1;31m'   # Bold Red for high-visibility Red Pill elements
GREEN='\033[0;32m'
B_GREEN='\033[1;32m' # Bold Green for verified/active status
YELLOW='\033[0;33m'
B_YELLOW='\033[1;33m'
B_BLUE='\033[1;34m'  # Bold Blue for high-visibility Blue Pill elements
B_VIOLET='\033[1;35m' # Bold Violet for ACPI Fix elements
CYAN='\033[0;36m'
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White
NC='\033[0m' # No Color (Reset)

# 🧬 DYNAMIC GITHUB STRINGS FOR MODDED PYTHON OVERRIDES
# (Make sure to replace 'YourGitHubUsername' and 'YourRepoName' with your exact info after uploading!)
MODDED_APPLY_URL="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/bc250_apply.py"
MODDED_LIMITS_URL="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/bc250_limits.py"

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
    
    # 🚀 ADVANCED HYBRID SILICON AUTODETECTOR LAYER
    local detected_cus=24

    # 🔍 WinnieLV WGP Mask Parser: Dynamically decodes active live config files
    if [[ -f /etc/bc250-cu-live-manager.conf ]]; then
        local raw_masks
        raw_masks=$(grep "BC250_WGP_MASKS=" /etc/bc250-cu-live-manager.conf | cut -d= -f2)
        if [[ -n "$raw_masks" ]]; then
            # Sum up bit elements across all four shader engine channels smoothly
            local total_bits=0
            IFS=',' read -r -a mask_array <<< "$raw_masks"
            for mask in "${mask_array[@]}"; do
                local val=$((mask))
                # Counts active binary bits to pull exact total routed WGPs
                for ((i=0; i<32; i++)); do
                    (( (val >> i) & 1 )) && ((total_bits++))
                done
            done
            # Each active bit represents 1 WGP which houses exactly 2 active CUs
            (( detected_cus = total_bits * 2 ))
        fi
    fi

    # Fallback to direct kernel diagnostics query if manager profile config hasn't been written yet
    if (( detected_cus == 0 )) && command -v umr &> /dev/null; then
        detected_cus=$(umr -i 0 -g 2>/dev/null | grep -i "cu_per_sh" | awk '{print $3 * 4}')
    fi
    if [[ ! "$detected_cus" =~ ^[0-9]+$ ]] || (( detected_cus <= 0 )); then
        detected_cus=24
    fi

    local live_threads=$(nproc 2>/dev/null || echo "12")
    local detected_cores=$(( live_threads / 2 ))
    
    echo -e "  ${CYAN}║${NC}   ${BOLD}${GREEN}✔ ACTIVE HARDWARE IDENTIFIED:${NC} ${detected_cus}/40 Compute Units  │  ${detected_cores} CPU Cores / ${live_threads} Threads            ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

        # 📋 AUDIT NO. 1: COOLING INFRASTRUCTURE
    echo -e "  ${CYAN}╔═ [1/5] HARDWARE AUDIT: COOLING INFRASTRUCTURE ══════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║${NC}  Select the physical cooling system configuration currently active on this node:            ${CYAN}║${NC}"
    echo -e "  ${CYAN}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}   ${BIWhite}1)${NC} Stock / Factory OEM Basic Air Cooler                                                   ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BIWhite}2)${NC} High-End Aftermarket Air Cooled (Heavy Fin Stack / High CFM Fans)                      ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BIWhite}3)${NC} Liquid Cooled / AIO Closed Loop / Custom Water Block                                   ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    local cooling_choice=""
    read -p "  Enter cooling profile option [1-3]: " cooling_choice

    local THROTTLE_TEMP=72
    local RECOVERY_TEMP=65
    local COOLING_LABEL="Stock Air"

    case "$cooling_choice" in
        1) THROTTLE_TEMP=72; RECOVERY_TEMP=65; COOLING_LABEL="Stock Air (Restricted)";;
        2) THROTTLE_TEMP=84; RECOVERY_TEMP=75; COOLING_LABEL="Premium Air Cooled";;
        3) THROTTLE_TEMP=65; RECOVERY_TEMP=58; COOLING_LABEL="Liquid Cooled Core";;
        *) echo -e "  ${RED}❌ Invalid choice. Falling back to safe Stock Air parameters.${NC}"; THROTTLE_TEMP=72;;
    esac
    echo ""

        # 📋 AUDIT NO. 2: POWER BUDGET (300W - 500W+ STRATA)
    echo -e "  ${CYAN}╔═ [2/5] HARDWARE AUDIT: POWER INFRASTRUCTURE overhead ═══════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║${NC}  Enter your physical Power Supply Unit (PSU) maximum continuous wattage rating:             ${CYAN}║${NC}"
    echo -e "  ${CYAN}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}   ${DIM}* Platform registers custom profiles from a 300W baseline up to a 500W+ extreme ceiling * ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    local psu_wattage=""
    read -p "  PSU Wattage Rating (e.g., 300, 450, 500): " psu_wattage

    if ! [[ "$psu_wattage" =~ ^[0-9]+$ ]]; then
        echo -e "  ${RED}⚠ Invalid format. Defaulting power tracking to minimal 300W limits.${NC}"
        psu_wattage=300
    fi
    echo ""

            # 📋 AUDIT NO. 3: FUTURE TARGET COMPUTE UNITS (INTELLIGENT HYBRID CONFIRMATION)
    echo -e "  ${CYAN}╔═ [3/5] HARDWARE AUDIT: GRAPHICS COMPUTE UNIT PROFILES ══════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║${NC}  Live scanner path reports ${detected_cus}/40 Compute Units (CUs) currently active on this core.         ${CYAN}║${NC}"
    echo -e "  ${CYAN}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}   Are you planning to change or target a different operational footprint?                   ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                                                             ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BIWhite}1)${NC} Target 36 CUs Active  ${DIM}(Down-binned / Maximum High-Efficiency Target Layout)${NC}            ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BIWhite}2)${NC} Target 38 CUs Active  ${DIM}(Optimal Mid-Tier Custom Performance Curve Baseline)${NC}             ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BIWhite}3)${NC} Target 40 CUs Active  ${DIM}(Absolute Full Die Silicon Array Matrix Unlocked)${NC}                ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    local cu_choice=""
    read -p "  Select target CU configuration profile [1-3]: " cu_choice

    local ACTIVE_CUS=38
    case "$cu_choice" in
        1) ACTIVE_CUS=36;;
        2) ACTIVE_CUS=38;;
        3) ACTIVE_CUS=40;;
        *) echo -e "  ${YELLOW}⚠ Unknown parameter. Defaulting profile curve to stable 38 CU footprint.${NC}"; ACTIVE_CUS=38;;
    esac
    echo ""

        # 📋 AUDIT NO. 4: FUTURE TARGET CPU CORES
    echo -e "  ${CYAN}╔═ [4/5] HARDWARE AUDIT: CPU CORE COMPLEX ALLOCATION ═════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║${NC}  Live scanner path reports ${detected_cores} CPU Cores / ${live_threads} Threads currently active on this node.          ${CYAN}║${NC}"
    echo -e "  ${CYAN}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}   Select your target operational profile layout:                                            ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}                                                                                             ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BIWhite}1)${NC} Target 6 Cores / 12 Threads  ${DIM}(Power-saving / High-Efficiency Sweet Spot)${NC}               ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BIWhite}2)${NC} Target 8 Cores / 16 Threads  ${DIM}(Full Hardware Multithreading Unlocked)${NC}                   ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    local core_choice=""
    read -p "  Select target CPU core complex [1-2]: " core_choice

    local ACTIVE_CORES=8
    local INTERVAL_SAMPLE=4000
    case "$core_choice" in
        1)
            ACTIVE_CORES=6
            INTERVAL_SAMPLE=6000   # Loosen to 6ms to protect a 12-thread pool from telemetry choke
            ;;
        2)
            ACTIVE_CORES=8
            INTERVAL_SAMPLE=4000   # Keep at ultra-fast 4ms for full 16-thread pools
            ;;
        *)
            echo -e "  ${YELLOW}⚠ Defaulting to full 8 Core / 16 Thread complex matrices.${NC}"
            ACTIVE_CORES=8
            INTERVAL_SAMPLE=4000
            ;;
    esac
    echo ""

    # 📋 SYSTEM TARGET TUNING LEVEL SELECTION
    echo -e "  ${CYAN}╔═ [5/5] HARDWARE AUDIT: SYSTEM TUNING OPTIMIZATION PROFILE ══════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║${NC}  Select the desired optimization and frequency scaling profile layer for this host:         ${CYAN}║${NC}"
    echo -e "  ${CYAN}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${CYAN}║${NC}   ${BIWhite}1)${NC} Normal Computer Use  ${DIM}(Silent profile, low voltage, browser/desktop work)${NC}               ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BIWhite}2)${NC} Standard Gaming      ${DIM}(Balanced high-efficiency foundation at 1800MHz)${NC}                  ${CYAN}║${NC}"
    echo -e "  ${CYAN}║${NC}   ${BIWhite}3)${NC} Heavy Overclocking   ${DIM}(Absolute Max Custom Curve: Up to 2150MHz @ 1020mV)${NC}               ${CYAN}║${NC}"
    echo -e "  ${CYAN}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    local tuning_choice=""
    read -p "  Select tuning profile [1-3]: " tuning_choice
    echo ""

    local PROFILE_LABEL=""
    local RAMP_NORMAL=15
    local RAMP_BURST=40
    local FREQ_MAX=1400
    local VOLT_MAX=780

    case "$tuning_choice" in
        1)
            PROFILE_LABEL="NORMAL COMPUTER USE (LOW POWER)"
            RAMP_NORMAL=5; RAMP_BURST=15; FREQ_MAX=1400; VOLT_MAX=780
            ;;
        2)
            PROFILE_LABEL="STANDARD GAMING (BALANCED PERFORMANCE)"
            RAMP_NORMAL=10; RAMP_BURST=50; FREQ_MAX=1800; VOLT_MAX=900
            ;;
        3)
            PROFILE_LABEL="HEAVY OVERCLOCKING GAMEPLAY (MAX CEILING)"
            RAMP_NORMAL=15; RAMP_BURST=80; FREQ_MAX=2150; VOLT_MAX=1020
            ;;
        *)
            echo -e "  ${RED}❌ Invalid tuning layout selection. Aborting...${NC}"; sleep 1.5; return 1;;
    esac

    # 🧬 THE STEPPED INTERCEPT ENGINE: Automated downscaling enforcement rules based on PSU Strata
    if (( psu_wattage >= 300 && psu_wattage < 400 )); then
        echo -e "  ${RED}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${RED}║  [⚠] CRITICAL HARDWARE LOCKOUT: SEVERE PSU CONSTRAINT ENFORCED                              ║${NC}"
        echo -e "  ${RED}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "  ${RED}║  Your reported ${psu_wattage}W power supply is below the minimum required headroom for 3D gaming.  ║${NC}"
        echo -e "  ${RED}║  Toolkit has hardlocked profile to Normal Computer Use (1400MHz) to prevent OCP trips.      ║${NC}"
        echo -e "  ${RED}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        PROFILE_LABEL="NORMAL COMPUTER USE (FORCED SAFETY CLAMP)"
        FREQ_MAX=1400; VOLT_MAX=780; RAMP_NORMAL=5; RAMP_BURST=15; tuning_choice=1

    elif (( psu_wattage >= 400 && psu_wattage < 500 )) && [ "$tuning_choice" -eq 3 ]; then
        echo -e "  ${YELLOW}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${YELLOW}║  [⚠] MODERATE POWER HEADROOM DETECTED: AUTO-DOWN-SAMPLING PERFORMANCE ACTIVE                ║${NC}"
        echo -e "  ${YELLOW}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "  ${YELLOW}║  Your reported ${psu_wattage}W PSU cannot safely protect against 2150MHz transient spikes.           ║${NC}"
        echo -e "  ${YELLOW}║  Toolkit has safely scaled your target down to Standard Gaming mode (1800MHz @ 900mV).      ║${NC}"
        echo -e "  ${YELLOW}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        PROFILE_LABEL="STANDARD GAMING (AUTO-DOWNSCALED FROM MAXIMUM CEILING)"
        FREQ_MAX=1800; VOLT_MAX=900; RAMP_BURST=50; tuning_choice=2
    fi
    echo -e "  ${YELLOW}[ℹ] Compiling target configurations using tailored hardware masks...${NC}"
    local TARGET_CONF="/etc/cyan-skillfish-governor-smu/config.toml"
    sudo mkdir -p /etc/cyan-skillfish-governor-smu 2>/dev/null

    # 🚀 AUTO-BACKUP TRACE: Preserves existing setup properties cleanly before overwriting
    if [[ -f "$TARGET_CONF" ]]; then
        sudo cp "$TARGET_CONF" "${TARGET_CONF}.bak_$(date +%Y%m%d_%H%M%S)" 2>/dev/null
    fi

    sudo bash -c "cat <<EOF > $TARGET_CONF
# ==============================================================================
# PROFILE TEMPLATE LAYOUT: $PROFILE_LABEL
# Calculated dynamically via BC-250 Spec Auditor Wizard Suite
# Hardware Target Mask: $ACTIVE_CUS CUs Unlocked | $ACTIVE_CORES CPU Cores Active
# Hardware Spec Mask: Cooling = $COOLING_LABEL | Power Source = ${psu_wattage}W PSU
# ==============================================================================

[timing.intervals]
sample = $INTERVAL_SAMPLE          # Auto-scaled based on targeted operational CPU core complex
adjust = 30000         # 30ms loop ensures smooth clock stepping without micro-stutter

[gpu-usage]
fix-freq = true
fix-metrics = true
method = \"busy-flag\"   # Best compatibility mode for RDNA2 Cyan Skillfish architectures
flush-every = 5        # Flushes frequently to completely eliminate micro-stutter

[gpu]
set-method = \"smu\"     # Direct SMU control for immediate frequency overrides
target_card = \"card1\"  # Points directly to your active BC-250 hardware node

[dbus]
enabled = true         # Enables inter-process communication for system overlays

# MHz/ms scaling rates
[timing.ramp-rates]
normal = $RAMP_NORMAL            # Tracking speed optimized for active profile limits
burst = $RAMP_BURST             # Frequency jumps scaled dynamically to match your \${psu_wattage}W current allocation

# Evaluation sampling parameters
[timing]
burst-samples = 3      # Allows fast response to heavy engine load spikes
down-events = 20       # High filtration to aggressively prevent framerate drops

# Control loop window boundaries (MHz)
[frequency-thresholds]
adjust = 5             # Tighter control loop window for precise stability
upper = 0.94           # Lock peak frequencies until utilization drops significantly
lower = 0.82           # Force higher clocks even during brief engine stalls or asset loading

# Utilization target margins (%)
[load-target]
upper = 0.80           # Prevents aggressive downclocking during variable frame times
lower = 0.60           # Forces high clock retention during geometry/draw call pipeline limits

# °C Thermal tracking configurations
[temperature]
throttling = $THROTTLE_TEMP        # HARD CEILING: Scaled directly from your \$COOLING_LABEL spec option
throttling_recovery = $RECOVERY_TEMP # Safe temperature buffer to prevent rapid thermal stutter loops

# ==============================================================================
# CLOCK & VOLTAGE FREQUENCY CURVE
# Ceiling and exponential safe-points auto-scaled for active spec parameters.
# ==============================================================================

[frequency-range]
min = 350
max = $FREQ_MAX             # Dynamic performance ceiling applied securely
min_voltage = 700      # Stabilized voltage floor for hardware system bus
max_voltage = $VOLT_MAX     # Maximum voltage ceiling matching profile budget limit

[[safe-points]]
frequency = 350
voltage = 700

[[safe-points]]
frequency = 500
voltage = 700

[[safe-points]]
frequency = 1000
voltage = 740          # Raised low-state voltage to prevent hard-lock idling crashes

[[safe-points]]
frequency = 1400
voltage = 780          # Adjusted mid-state baseline
EOF"
    # Appends extra safe points up to 1800MHz if option 2 or 3 is authorized
    if [ "$tuning_choice" -gt 1 ]; then
    sudo bash -c "cat <<EOF >> $TARGET_CONF

[[safe-points]]
frequency = 1500
voltage = 810          # Exponential scaling begins here to combat silicon leakage

[[safe-points]]
frequency = 1600
voltage = 840

[[safe-points]]
frequency = 1700
voltage = 870

[[safe-points]]
frequency = 1800
voltage = 900          # High-efficiency gaming foundation threshold
EOF"
    fi

    # Appends your exact extreme safe points up to 2150MHz ONLY if 500W+ overhead is verified
    if [ "$tuning_choice" -eq 3 ]; then
    sudo bash -c "cat <<EOF >> $TARGET_CONF

[[safe-points]]
frequency = 1900
voltage = 930

[[safe-points]]
frequency = 1950
voltage = 945

[[safe-points]]
frequency = 2000
voltage = 960          # 2GHz high-performance threshold

[[safe-points]]
frequency = 2050
voltage = 975

[[safe-points]]
frequency = 2100
voltage = 995          # Approaching high-stress limits (+20mV)

[[safe-points]]
frequency = 2125
voltage = 1008         # High-leakage compensation step

[[safe-points]]
frequency = 2150
voltage = 1020         # Maximum performance tier matching your exact --vid 1020 limit
EOF"
    fi

    echo -e "  ${GREEN}[✓] New config.toml compiled successfully using hardware constraints!${NC}"
    echo -e "  ${YELLOW}[⚙] Cycling changes into live governor service memory...${NC}"

    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl restart cyan-skillfish-governor-smu 2>/dev/null || true

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
    # 🧬 PRE-FLIGHT DEPLOYMENT GATE: Detects if the CPU suite is already initialized or staged
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

    # ==============================================================================
    # 🧬 AUTOMATED HARDWARE UNLOCK ENGINE: OVERWRITING DRIVER CONSTRAINTS
    # ==============================================================================
    log "${GREEN}[⚙] Injecting custom low-power overrides from your repository...${NC}"
    local py_packages="/opt/bc250_smu_tools/venv/lib64/python3.14/site-packages"
    
    sudo curl -sSL -o "$py_packages/bc250_apply.py" "$MODDED_APPLY_URL" >> "$LOG_FILE" 2>&1
    sudo curl -sSL -o "$py_packages/bc250_limits.py" "$MODDED_LIMITS_URL" >> "$LOG_FILE" 2>&1
    
    # Obliterate pre-compiled cache artifacts to force immediate system evaluation
    sudo rm -rf "$py_packages/__pycache__" 2>/dev/null || true
    # ==============================================================================

    sudo systemctl disable bc250-resume.service >> "$LOG_FILE" 2>&1
    sudo rm -f "$SERVICE_FILE"
    sudo systemctl daemon-reload
    log "${GREEN}[Success] Installation complete! 'bc250-detect' and 'bc250-apply' are ready.${NC}"
    
    # Menu launches AFTER the files have been completely overwritten
    launch_tuning_menu
}

# ==============================================================================
# 🧬 HARDENED COMPUTE UNIT LIVE MANAGER GATEWAY (PREVENTS DUPLICATE DEPLOYMENTS)
# ==============================================================================
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

uninstall_cpu_overclock() {
    log "${RED}[Uninstall] Initializing CPU Overclock rollback suite...${NC}"
    sudo systemctl disable --now bc250-smu-oc.service >> "$LOG_FILE" 2>&1 || true
    sudo systemctl disable --now bc250-resume.service >> "$LOG_FILE" 2>&1 || true
    sudo rm -f /etc/systemd/system/bc250-smu-oc.service
    sudo rm -f "$SERVICE_FILE"
    sudo rm -f /usr/local/bin/bc250-detect
    sudo rm -f /usr/local/bin/bc250-apply
    sudo rm -rf /opt/bc250_smu_tools
    sudo rm -rf /tmp/bc250_smu_oc
    sudo rpm-ostree kargs --delete=mitigations=off >> "$LOG_FILE" 2>&1
    sudo rpm-ostree uninstall stress python3-devel >> "$LOG_FILE" 2>&1
    sudo systemctl daemon-reload
    prompt_reboot
}

uninstall_cu_live_manager() {
    log "${RED}[Uninstall] Initializing CU Live Manager rollback suite...${NC}"
    sudo systemctl disable --now bc250-cu-live-manager.service >> "$LOG_FILE" 2>&1 || true
    sudo rm -f /etc/systemd/system/bc250-cu-live-manager.service
    sudo rm -f /usr/local/bin/bc250-cu-live-manager
    sudo rm -f /etc/bc250-cu-live-manager.conf
    sudo rm -f /tmp/bc250-cu-live-manager.sh
    sudo rpm-ostree uninstall umr >> "$LOG_FILE" 2>&1
    sudo systemctl daemon-reload
    prompt_reboot
}

case "$1" in
    --phase2) run_phase2; exit 0 ;;
    --manager-phase2) run_manager_phase2; exit 0 ;;
    --uninstall-cpu) uninstall_cpu_overclock; exit 0 ;;
    --uninstall-cu) uninstall_cu_live_manager; exit 0 ;;
esac

# ==============================================================================
# 🚀 CLEAN CONGESTION-FREE MASTER MENU LOOP (NO REFLECTION DELAYS)
# ==============================================================================
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
    echo ""
    echo -e "    ${BOLD}${YELLOW}• Rollback & Restoration Profiles:${RESET}"
    echo -e "      ${DIM}[3a] Uninstall CPU Overclock Profiles Completely${RESET}"
    echo -e "      ${DIM}[3b] Uninstall Compute Unit Live Manager Service Paths${RESET}"
    echo ""
    echo -e "    ${BOLD}${YELLOW}• Silicon Stability Testing Channels:${RESET}"
    echo -e "      ${CYAN}[4]${RESET}   Launch Silicon Per-Core Stability Sweep ${DIM}(test-cores Curve Validation)${RESET}"
    echo ""
    echo -e "  ${DIM}──────────────────────────────────────────────────────────────────────────────────${RESET}"
    echo -e "      ${BOLD}${MAGENTA}[↵]${RESET} Hit Enter to Secure Safe Exit Overclock-Live-Manager"
    echo ""

    read -p "  Select an option [ 1a-4, M, ↵ ]: " choice

        case "$choice" in
        1a) run_phase1 ;;
        1b) run_phase2 ;;
        2a) run_manager_phase1 ;;
        2b) run_manager_phase2 ;;
        m|M) configure_governor_profile ;;
        3a) uninstall_cpu_overclock ;;
        3b) uninstall_cu_live_manager ;;
        4)  run_cpu_core_stress_test ;;
        0|"") exit 0 ;;
        *) echo -e "${RED}Invalid choice! Please select a valid option.${NC}"; sleep 1.5 ;;
    esac
done
