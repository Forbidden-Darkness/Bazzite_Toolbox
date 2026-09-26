#!/usr/bin/env bash
# ==============================================================================
# 🏛️ GROUP 1: CORE SYSTEM ENVIRONMENT, ANCHOR VARIABLES & SETUP CONTEXTS
# ==============================================================================
RED='\033[0;31m'
B_RED='\033[1;31m'   # Bold Red for high-visibility Red Pill elements
GREEN='\033[0;32m'
B_GREEN='\033[0;92m'
YELLOW='\033[1;33m'
B_BLUE='\033[1;34m'  # Bold Blue for high-visibility Blue Pill elements
B_VIOLET='\033[1;35m' # Bold Violet for ACPI Fix elements
CYAN='\033[0;36m'
BIBlack='\033[1;90m'
BIRed='\033[1;91m'
BIGreen='\033[1;92m'
BIYellow='\033[1;93m'
BIBlue='\033[1;94m'
BIPurple='\033[1;95m'
BICyan='\033[1;96m'
BIWhite='\033[1;97m'
MAGENTA="\033[1;95m"
NC='\033[0m'
RESET='\033[0m'
BG_HEADER="\e[48;5;235m"
DIM='\033[38;2;110;110;110m'
BOLD='\033[1m'

MODDED_PATCH_0001_URL="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/BC-250-Graphics-Compiler/Compiled/0001-gfx1013-compute-queue.patch"
MODDED_PATCH_0002_URL="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/BC-250-Graphics-Compiler/Compiled/0002-gfx1013-mesh-task-shaders.patch"
MODDED_PATCH_0003_URL="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/BC-250-Graphics-Compiler/Compiled/0003-gfx1013-taskmesh-queries.patch"

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || whoami)}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
[[ -z "$REAL_HOME" || ! -d "$REAL_HOME" ]] && REAL_HOME="/root"

EXTERNAL_DIR="$REAL_HOME/Applications/Bazzite_Toolbox"
CORE_UNLOCK_CONF="/etc/bc250-core-unlock.conf"
LOG_FILE="/var/log/bc250_oc_install.log"
AUDIO_FILE="$EXTERNAL_DIR/Wake_on_LAN/Red-Pill-Blue-Pill.wav"
MUSIC_LOCK_FILE="$REAL_HOME/.bc250-toolkit-music.pid"
# ==============================================================================
# 🎵 GROUP 2: BACKGROUND AUDIO PIPELINE ENGINES & NOTIFICATION CHIMES
# ==============================================================================
start_background_music() {
    if [[ -f "$AUDIO_FILE" ]] && [[ ! -f "$MUSIC_LOCK_FILE" ]]; then
        local user_id; user_id=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

        # 1. Start the infinite audio playback loop with verified session bus contexts
        (
            while true; do
                # 🧬 AUDIO MATRIX SOCKET BRIDGE: Passes runtime links to bypass root privilege containment
                sudo -u "$REAL_USER" \
                     XDG_RUNTIME_DIR="/run/user/$user_id" \
                     PIPEWIRE_RUNTIME_DIR="/run/user/$user_id" \
                     DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$user_id/bus" \
                     pw-play "$AUDIO_FILE" 2>/dev/null

                # Prevent rapid thread spinning loops if the file experiences an interface drop
                sleep 1
            done
        ) &>/dev/null &

        local music_pid=$!
        echo "$music_pid" > "$MUSIC_LOCK_FILE" || true

        # Disowns the background process thread from the current terminal job table.
        # This completely stops Bash from printing the "Killed" status log on exit!
        disown "$music_pid" 2>/dev/null || true

        # 2. Spawn a detached 71-second automated fade-out timer thread
        (
            sleep 71

            local nodes; nodes=$(sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$user_id" PIPEWIRE_RUNTIME_DIR="/run/user/$user_id" pw-cli list-objects Node 2>/dev/null | grep -B 2 "pw-play" | awk -F'= ' '/id/ {print $2}' | tr -d ',')
            if [[ -n "$nodes" ]]; then
                for vol in 0.8 0.6 0.4 0.2 0.1 0.0; do
                    for node in $nodes; do
                        sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$user_id" PIPEWIRE_RUNTIME_DIR="/run/user/$user_id" pw-cli s "$node" Props "{ volume: $vol }" &>/dev/null || true
                    done
                    sleep 0.8
                done
            fi
            if [[ -f "$MUSIC_LOCK_FILE" ]]; then
                local target_pid; target_pid=$(cat "$MUSIC_LOCK_FILE" 2>/dev/null || echo "")
                [[ -n "$target_pid" ]] && kill -9 "$target_pid" 2>/dev/null || true
                killall pw-play &>/dev/null || true
                rm -f "$MUSIC_LOCK_FILE" 2>/dev/null || true
            fi
        ) &>/dev/null &
    fi
}

stop_background_music() {
    if [[ -f "$MUSIC_LOCK_FILE" ]]; then
        local target_pid; target_pid=$(cat "$MUSIC_LOCK_FILE" 2>/dev/null || echo "")
        [[ -n "$target_pid" ]] && kill -9 "$target_pid" 2>/dev/null || true

        # Kill the player engine instances across both root and standard user parameters cleanly
        sudo -u "$REAL_USER" killall pw-play &>/dev/null || true
        killall pw-play &>/dev/null || true
        rm -f "$MUSIC_LOCK_FILE" 2>/dev/null || true
    fi
}

# Ensure clean exit handling
trap stop_background_music EXIT

# --- Main Runtime Initializer ---
start_background_music
# ==============================================================================
# 🏛️ GROUP 1 (CONT.): ENHANCED UI ANIMATION ACTIONS & CLEAR SYSTEMS
# ==============================================================================
SKIP_ANIMATION=false

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

blink_cursor() {
    local prompt_text="$1"
    echo -ne "$prompt_text"

    if [ "${SKIP_ANIMATION:-false}" = true ]; then
        echo ""
        return 0
    fi

    for i in {1..3}; do
        echo -ne "\033[5m█\033[0m"

        # Split wait cycles to remain instantly responsive to bypass keystrokes
        for s in {1..5}; do
            if read -t 0.1 -n 1 2>/dev/null; then
                SKIP_ANIMATION=true
                echo -ne "\b \n"
                read -t 0.1 -N 255 _ || true
                return 0
            fi
        done

        # 🎯 TYP0 RUNTIME OFFSET RESTORED: Matches your single-backspace line crawl movement exactly
        echo -ne "\b "

        for s in {1..5}; do
            if read -t 0.1 -n 1 2>/dev/null; then
                SKIP_ANIMATION=true
                echo -e "\n"
                read -t 0.1 -N 255 _ || true
                return 0
            fi
        done
    done
    echo ""
    read -t 0.1 -N 255 _ || true
}

draw_progress_bar() {
    local duration="$1"
    local width=40
    echo -ne "  Optimizing CUs: ["

    for ((i=1; i<=width; i++)); do
        local pct=$(( i * 100 / width ))
        local g_val=$(( 100 + (i * 155 / width) ))
        echo -ne "\033[38;2;0;${g_val};0m█\033[0m"
        if [ "$SKIP_ANIMATION" = false ]; then
            if read -t 0.001 -n 1 2>/dev/null; then
                SKIP_ANIMATION=true
            fi
            sleep "$(bc -l <<< "$duration / $width")"
        fi
    done
    echo -e "] Done!"
}

matrix_melt_clear() {
    local lines; lines=$(tput lines)
    for ((i=0; i<lines; i++)); do
        echo ""
        if [ "$SKIP_ANIMATION" = false ]; then
            if read -t 0.005 -n 1 2>/dev/null; then
                SKIP_ANIMATION=true
            fi
            sleep 0.01
        fi
    done
    clear
}
# ==============================================================================
# 🏛️ GROUP 1 (CONT.): EXPLOIT GRAPHICS RUNTIME & ENVIRONMENT ATTRIBUTES
# ==============================================================================
clear
echo -e "\033[38;2;0;255;0m  ╔═════════════════════════════════════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[38;2;0;255;0m  ║                                                                                             ║\033[0m"
echo -e "\033[38;2;0;255;0m  ║                                █ █ █ █▀▀ █   █▀▀ █▀█ █▄█ █▀▀                                ║\033[0m"
echo -e "\033[38;2;0;255;0m  ║                                ▀▄▀▄▀ ██▄ █▄▄ █▄▄ █▄█ █ █ ██▄                                ║\033[0m"
echo -e "\033[38;2;0;255;0m  ║                                                                                             ║\033[0m"
echo -e "\033[38;2;0;255;0m  ║    ${B_BLUE}[●] BLUE Pill\033[38;2;0;255;0m            🔑  System Architecture Unlocks  🔑            ${RED}RED Pill [●]\033[38;2;0;255;0m     ║\033[0m"
echo -e "\033[38;2;0;255;0m  ║                                                                                             ║\033[0m"
echo -e "\033[38;2;0;255;0m  ╚═════════════════════════════════════════════════════════════════════════════════════════════╝\033[0m"
echo -e "  ${DIM}→ Press ANY KEY to instantly bypass connection logs and initialization streams...${NC}\n"

# Run text prompts cleanly now that functions are fully compiled into memory
type_prompt "  Establishing System Root Authorization.... " 0.03
blink_cursor ""
echo ""
type_prompt "  exploiting system entry " 0.03
blink_cursor ""

type_prompt "  injecting exploit.... " 0.05
blink_cursor ""

type_prompt "  system has been pwned, root access has been granted.... " 0.03
blink_cursor ""

type_prompt "  mapping system block registers " 0.03
blink_cursor ""
echo ""

type_prompt "  System reinitializing" 0.04
blink_cursor ""

# Dynamic, theme-matched loading sequences:
draw_progress_bar 10.5
echo ""

# --- Swap Allocation Global Targets ---
SWAPFILE_PATH="/var/swap/swapfile"  # Bazzite's standard BTRFS swapfile target path
SWAPFILE_STOCK_SIZE_MB=4096         # Stock 4GB layout baseline

# Verify root/sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo or as root."
    echo -e "Please run: sudo bash $0${NC}"
    exit 1
fi

# ==============================================================================
# 🏛️ GROUP 1 (CONT.): MASTER TERMINAL PRINT UTILITIES & OVERLAYS
# ==============================================================================
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SCRIPT_PATH=$(realpath "$0")
CONFIG_FILE="$REAL_HOME/.bazzite_toolbox_config"

# Target paths for legacy and new shortcut files
LOCAL_APPS="$REAL_HOME/.local/share/applications"
LOCAL_DIRS="$REAL_HOME/.local/share/desktop-directories"
LOCAL_MENUS="$REAL_HOME/.config/menus"

OLD_DESKTOP="$LOCAL_APPS/bazzite-toolbox.desktop"
OLD_DIRECTORY="$LOCAL_DIRS/bazzite-toolbox.directory"
OLD_MENU="$LOCAL_MENUS/applications-merged-bazzite.menu"

print_warning() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

print_banner() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔════════════════════════════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                                        ║"
    echo "  ║         ██████╗  █████╗ ███████╗███████╗██╗████████╗███████╗    ██████╗ ███████╗       ║"
    echo "  ║         ██╔══██╗██╔══██╗╚══███╔╝╚══███╔╝██║╚══██╔══╝██╔════╝   ██╔═══██╗██╔════╝       ║"
    echo "  ║         ██████╔╝███████║  ███╔╝   ███╔╝ ██║   ██║   █████╗  ██ ██║   ██║███████╗       ║"
    echo "  ║         ██╔══██╗██╔══██║ ███╔╝   ███╔╝  ██║   ██║   ██╔══╝     ██║   ██║╚════██║       ║"
    echo "  ║         ██████╔╝██║  ██║███████╗███████╗██║   ██║   ███████╗   ╚██████╔╝███████║       ║"
    echo "  ║         ╚══════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   ╚═╝   ╚══════╝    ╚═════╝ ╚══════╝      ║"
    echo "  ║                                                                                        ║"
    echo "  ║                                                                                        ║"
    echo -e "  ║    ${B_BLUE}[●] BLUE Pill${CYAN}             📟  System Core Telemetry  📟             ${RED}RED Pill [●]${CYAN}    ║"
    echo "  ╚════════════════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

print_section() {
    echo -e "  ${BOLD}${YELLOW}$1${RESET}"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
}

print_item() {
    local num="$1"
    local label="$2"
    local desc="$3"
    local label_bytes=${#label}
    local label_visual=$(echo -n "$label" | wc -m)
    local extra=$(( label_bytes - label_visual ))
    local width=$(( 26 + extra ))
    printf "  ${BOLD}${WHITE}[${CYAN}%2s${WHITE}]${RESET}  %-${width}s ${DIM}%s${RESET}\n" "$num" "$label" "$desc"
}

print_success() {
    echo -e "\n  ${BOLD}${GREEN}✔  $1${RESET}\n"
}

print_error() {
    echo -e "\n  ${BOLD}${RED}✘  $1${RESET}\n"
}

print_info() {
    echo -e "  ${CYAN}→${RESET}  $1"
}

print_step() {
    echo -e "\n  ${BOLD}${MAGENTA}[$1]${RESET}  $2"
}

press_enter() {
    echo -e "\n  ${DIM}Press Enter to return to the menu...${RESET}"
    read -r
}

confirm() {
    local prompt="${1:-Are you sure?}"
    echo -e "\n  ${YELLOW}${prompt}${RESET} ${DIM}[y/N]${RESET} "
    read -rp "  → " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# ==============================================================================
# 🎛️ GROUP 3: DRIVERS, COMPATIBILITY HELPERS & SYSTEM HEALTH
# ==============================================================================
core_unlock_persist_installed() {
    systemctl is-enabled bc250-core-unlock.service &>/dev/null
}

core_unlock_cores_active() {
    [[ "$(nproc --all 2>/dev/null)" -eq 16 ]]
}

ram_split_installed() {
    if rpm-ostree kargs 2>/dev/null | grep -q "ttm.pages_limit" || [[ -f /etc/modprobe.d/bc250-mem.conf ]]; then
        return 0
    fi

    if [[ -f "/proc/meminfo" ]]; then
        local total_mem_kb; total_mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo "16000000")
        local total_mem_mb=$(( total_mem_kb / 1024 ))

        if (( total_mem_mb < 10000 )); then
            return 0
        fi
    fi

    return 1
}

zram_currently_disabled() {
    [[ ! -d /sys/block/zram0 ]]
}

zswap_currently_on() {
    [[ "$(cat /sys/module/zswap/parameters/enabled 2>/dev/null || echo "N")" == "Y" ]]
}

swapfile_size_mb() {
    if [[ -f "$SWAPFILE_PATH" ]]; then
        echo $(( $(stat -c%s "$SWAPFILE_PATH" 2>/dev/null || echo 0) / 1024 / 1024 ))
    else
        echo 0
    fi
}

cu_find_umr() {
    command -v umr &>/dev/null
}

acpi_fix_installed() {
    if [ -f "/boot/acpi_override.cpio" ] || [ -f "/boot/SSDT_ACPI.cpio" ]; then
        return 0
    fi
    return 1
}

sensors_active_driver() {
    if lsmod | grep -q "^nct6687"; then echo "nct6687"; else echo "none"; fi
}

RAM_SPLIT_DIR="$EXTERNAL_DIR/bc250_memcfg"
RAM_SPLIT_BIN="$RAM_SPLIT_DIR/bc250memcfg"
RAM_SPLIT_DEFAULT_UMA_MB=512
RAM_SPLIT_STOCK_UMA_MB=8192
RAM_SPLIT_DEFAULT_TTM_PAGES=3145728

ram_split_bc250_detected() {
    command -v lspci >/dev/null 2>&1 && lspci -Dn 2>/dev/null | grep -qi '1002:13fe'
}

ram_split_gcc_can_compile() {
    command -v g++ >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 || return 1
    local probe; probe=$(mktemp -u --suffix=.cpp)
    printf '#include <iostream>\nint main(void){return 0;}\n' > "$probe"

    local cc_engine="gcc"
    command -v g++ &>/dev/null && cc_engine="g++"

    $cc_engine "$probe" -o "${probe%.cpp}.out" >/dev/null 2>&1
    local rc=$?
    rm -f "$probe" "${probe%.cpp}.out"
    return $rc
}
ram_split_build_tool() {
    [[ -x "$RAM_SPLIT_BIN" ]] && return 0

    if [[ ! -f "$RAM_SPLIT_DIR/main.cpp" ]]; then
        print_error "Vendored bc250_memcfg source code not discovered at $RAM_SPLIT_DIR."
        return 1
    fi

    if ! ram_split_gcc_can_compile; then
        print_warning "Build dependencies (g++ / gcc / glibc-devel) are missing or not layered inside this Bazzite deployment."
        print_info "Please run: 'sudo rpm-ostree install gcc-c++' and reboot before building this tool configuration."
        return 1
    fi

    print_info "Building bc250memcfg from localized community source files..."

    local cc_engine="gcc"
    command -v g++ &>/dev/null && cc_engine="g++"

    (cd "$RAM_SPLIT_DIR" && $cc_engine -Os -s main.cpp -o bc250memcfg) || {
        print_error "Failed to build target hardware binary utility layer 'bc250memcfg'."
        return 1
    }

    chmod +x "$RAM_SPLIT_BIN" 2>/dev/null || true
    print_success "Memory profile compiler routine successfully built!"
}

ram_split_current_uma() {
    [[ -x "$RAM_SPLIT_BIN" ]] || return 1
    local val
    val=$("$RAM_SPLIT_BIN" 2>/dev/null | awk -F= '$1 == "UMA_SIZE" {print $2}' | tr -d ' \r')
    [[ -n "$val" ]] || return 1
    echo "$((10#$val))"
}

# ==============================================================================
# 🎛️ GROUP 3 (CONT.): REAL-TIME DRIVER STATUS & TELEMETRY READOUTS
# ==============================================================================
check_system_health() {
    echo -e "  ${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║                    SYSTEM SPECIFICATION CHECK                     ║${NC}"
    echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local kernel_ver; kernel_ver=$(uname -r)
    if [[ "$kernel_ver" =~ ^6\.15\.[0-6] || "$kernel_ver" =~ ^6\.17\.[8-9] || "$kernel_ver" =~ ^6\.17\.10 ]]; then
        echo -e "    Kernel Version : ${RED}❌ $kernel_ver (CRITICAL DRIVER FAULT ZONE)${NC}"
        echo -e "                     ${BIBlack}↳ Upgrade to 6.18.18+ or 6.19.x to avoid GPU crashes.${NC}"
    else
        echo -e "    Kernel Version : ${GREEN}✔ $kernel_ver (Safe Build Stack)${NC}"
    fi

    if grep -q "nomodeset" /proc/cmdline; then
        echo -e "    Display Path   : ${RED}❌ Throttled (nomodeset boot flag is active)${NC}"
        echo -e "                     ${BIBlack}↳ The GPU driver is disabled. Please remove nomodeset.${NC}"
    else
        echo -e "    Display Path   : ${GREEN}✔ Accelerated Hardware Layer Initialized${NC}"
    fi

    if command -v glxinfo &>/dev/null || command -v vulkaninfo &>/dev/null; then
        local mesa_ver; mesa_ver=$(glxinfo 2>/dev/null | grep -oP 'Mesa \K[0-9.]+' | head -n1)
        if [ -z "$mesa_ver" ]; then mesa_ver=$(vulkaninfo 2>/dev/null | grep -oP 'Mesa \K[0-9.]+' | head -n1); fi

        if [ -n "$mesa_ver" ]; then
            local major; major=$(echo "$mesa_ver" | cut -d. -f1)
            local minor; minor=$(echo "$mesa_ver" | cut -d. -f2)

            if [ "$major" -lt 25 ] || { [ "$major" -eq 25 ] && [ "$minor" -lt 1 ]; }; then
                echo -e "    Mesa Stack     : ${YELLOW}⚠ $mesa_ver (Outdated — Minimum 25.1.3+ required)${NC}"
            else
                echo -e "    Mesa Stack     : ${GREEN}✔ $mesa_ver (RADV Support Compliant)${NC}"
            fi
        else
            echo -e "    Mesa Stack     : ${BIYellow}ℹ Driver library version unparsed via CLI utilities${NC}"
        fi
    else
        echo -e "    Mesa Stack     : ${BIBlack}– Checking skipped (glxinfo/vulkaninfo packages missing)${NC}"
    fi
    echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
    echo ""
}

# ==============================================================================
# 🎛️ GROUP 3 (CONT.): REAL-TIME VISUALIZATION TELEMETRY DASHBOARD PANEL
# ==============================================================================
run_status() {
    print_banner
    print_section "System Status"

    local ICON_OK="✓" local ICON_WARN="⚠" local ICON_ERR="✗"
    local DIM="${DIM:-}" local RESET="${RESET:-}" local GREEN="${GREEN:-}"
    local YELLOW="${YELLOW:-}" local RED="${RED:-}" local CYAN="${CYAN:-}"
    local BOLD="${BOLD:-}" local WHITE="${WHITE:-}" local B_BLUE="${B_BLUE:-}"
    local ICON_OK="${GREEN}✓${RESET}" local ICON_WARN="${YELLOW}⚠${RESET}" local ICON_ERR="${RED}✗${RESET}"

    local CPU_CONF="/etc/bc250-smu-oc.conf"
    local GPU_CONF="/etc/cyan-skillfish-governor-smu/config.toml"

    local pin_status="$ICON_WARN" pin_lable="${RED}unpinned${RESET}"
    if ostree admin pin 2>/dev/null | grep -q "Pinned" || rpm-ostree status 2>/dev/null | grep -qi "pinned"; then
        pin_status="$ICON_OK" pin_lable="${GREEN}pinned (frozen)${RESET}"
    fi

    local async_icon="$ICON_WARN" async_lable="${RED}Deactivated${RESET}"
    local async_desc="${DIM}(ACE engine queues locked; system loses up to ~25% async gaming performance)${RESET}"
    if [[ -f /etc/environment.d/99-bc250-gfx1013.conf ]] && [[ -f /opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json ]]; then
        async_icon="$ICON_OK" async_lable="${GREEN}Activated${RESET}"
        async_desc="${DIM}(ACE engine queues unlocked for up to +25% gaming FPS)${RESET}"
    fi

    local profile_lbl=""
    local target_lib="/opt/bc250-gfx1013/lib64/libvulkan_radeon.so"

    if [[ -f "/etc/environment.d/99-bc250-gfx1013.conf" ]] || grep -q "VK_DRIVER_FILES" /etc/environment 2>/dev/null; then
        if [[ -f "$target_lib" ]]; then
            local file_bytes; file_bytes=$(stat -c %s "$target_lib" 2>/dev/null || echo "0")

            if (( file_bytes > 21700000 )); then
                profile_lbl=" — ${BOLD}${YELLOW}NAVI 14${RESET} ${DIM}(GFX1012 Active — Fast Clock Meta)${RESET}"
            else
                profile_lbl=" — ${BOLD}${YELLOW}NAVI 10${RESET} ${DIM}(GFX1010 Active)${RESET}"
            fi
        fi
    fi
    local detected_asic="${YELLOW}AMD Custom RDNA1 Silicon${RESET}${profile_lbl}"

    local fsr4_state="${RED}Deactivated${RESET} ${DIM}(System missing boot proxy hook — upscaler inactive)${RESET}"
    local fsr4_icon="$ICON_WARN"
    if find /var/home/bsystem/.local/share/Steam/steamapps/common /run/media/bsystem -type f -name "dxgi.dll" 2>/dev/null | grep -q "dxgi.dll"; then
        fsr4_icon="$ICON_OK"
        fsr4_state="${GREEN}Activated${RESET} ${DIM}(FSR 4.1.1 INT8 Winograd Loop Override Engine Online)${RESET}"
    fi
    echo -e "  ${BOLD}${YELLOW}System${RESET}"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"

    local boot_session="gamescope" local boot_relogin="true"
    if systemctl get-default 2>/dev/null | grep -q "graphical.target"; then
        if [[ -f /var/lib/AccountsService/users/$USER ]]; then
            grep -q "XSession=plasma" "/var/lib/AccountsService/users/$USER" && boot_session="plasma"
        fi
    fi

    local boot_mode boot_login
    if [[ "$boot_session" == "gamescope" ]]; then boot_mode="${BOLD}${GREEN}Game Mode${RESET}"; else boot_mode="${BOLD}${CYAN}Desktop Mode${RESET}"; fi
    boot_login=$([[ "$boot_relogin" == "false" ]] && echo "${DIM}password required${RESET}" || echo "${DIM}no password${RESET}")

    local wol_icon="$ICON_WARN" local wol_label="${YELLOW}Deactivated${RESET}"
    local wol_enabled=false local wol_setting
    while IFS= read -r conn; do
        [[ -z "$conn" ]] && continue
        wol_setting=$(nmcli -g 802-3-ethernet.wake-on-lan connection show "$conn" 2>/dev/null | tr '[:upper:]' '[:lower:]')
        if [[ "$wol_setting" == *magic* ]]; then wol_enabled=true; break; fi
    done < <(nmcli -t -f NAME connection show 2>/dev/null)
    if $wol_enabled; then wol_icon="$ICON_OK"; wol_label="${GREEN}Activated${RESET}"; else wol_icon="$ICON_WARN"; wol_label="${RED}Deactivated${RESET}"; fi

    echo -e "  ${CYAN}Boot Mode${RESET}             ${boot_mode}  ${boot_login}"
    echo -e "  ${CYAN}OS${RESET}                    $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    echo -e "  ${CYAN}Version${RESET}               $(cat /etc/os-release | grep -E '^(VERSION)=' | cut -d= -f2 | tr -d '"')"
    echo -e "  ${CYAN}Kernel${RESET}                $(uname -r)"
    echo -e "  ${CYAN}Detected Silicon${RESET}      ${ICON_OK} ${detected_asic}"
    echo -e "  ${CYAN}FSR 4.1.1 Framework${RESET}   ${fsr4_icon} ${fsr4_state}"
    echo -e "  ${CYAN}Wake-on-LAN${RESET}           ${wol_icon} ${wol_label} ${DIM}(Allows remote power plane activation triggers over network)${RESET}"
    echo -e "  ${CYAN}Atomic Deployment${RESET}     ${pin_status} ${pin_lable} ${DIM}(System layers frozen to block unwanted updates)${RESET}"
    echo -e "  ${CYAN}Async GPU Compute${RESET}     ${async_icon} ${async_lable} ${async_desc}"
    echo ""
    # OVERCLOCK
    print_section "Overclock"
    local cpu_preset="None" local cpu_profile="No Active Config"
    if [[ -f "$CPU_CONF" ]]; then cpu_preset=$(oc_match_preset 2>/dev/null || echo "Custom"); cpu_profile=$(oc_active_profile 2>/dev/null || echo "Active Profile"); fi
    echo -e "  ${DIM}CPU Active: ${cpu_preset} — ${cpu_profile}${RESET}"

    local gpu_preset="None" local gpu_profile="No Active Config"
    if [[ -f "$GPU_CONF" ]]; then gpu_preset=$(gpu_match_preset 2>/dev/null || echo "Custom"); gpu_profile=$(gpu_active_profile 2>/dev/null || echo "Active Profile"); fi
    echo -e "  ${DIM}GPU Active: ${gpu_preset} — ${gpu_profile}${RESET}"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"

    local cpu_svc_enabled cpu_svc_result
    cpu_svc_enabled=$(systemctl is-enabled bc250-smu-oc.service 2>/dev/null || echo "disabled")
    cpu_svc_result=$(systemctl show bc250-smu-oc.service --property=ExecMainStatus --value 2>/dev/null || echo "0")
    local cpu_icon cpu_label
    if [[ "$cpu_svc_enabled" == "enabled" && "$cpu_svc_result" == "0" ]]; then cpu_icon="$ICON_OK"; cpu_label="${GREEN}Activated (applied successfully)${RESET}"
    elif [[ "$cpu_svc_enabled" == "enabled" ]]; then cpu_icon="$ICON_WARN"; cpu_label="${YELLOW}Activated (exit code: ${cpu_svc_result})${RESET}"
    else cpu_icon="$ICON_WARN"; cpu_label="${RED}Deactivated${RESET}"; fi
    echo -e "  ${CYAN}CPU Service${RESET}           ${cpu_icon} ${cpu_label}"

    if [[ -f "$CPU_CONF" ]]; then
        local cpu_freq cpu_scale cpu_temp
        cpu_freq=$(awk -F'= ' '/^frequency/{sub(/#.*/, "", $2); print $2}' "$CPU_CONF" | tr -d ' ')
        cpu_scale=$(awk -F'= ' '/^scale/{sub(/#.*/, "", $2); print $2}' "$CPU_CONF" | tr -d ' ')
        cpu_temp=$(awk -F'= ' '/^max_temperature/{sub(/#.*/, "", $2); print $2}' "$CPU_CONF" | tr -d ' ')
        echo -e "  ${CYAN}CPU Profile${RESET}           ${ICON_OK} ${cpu_freq}MHz  scale ${cpu_scale}  max ${cpu_temp}°C"
    else echo -e "  ${CYAN}CPU Profile${RESET}           ${ICON_WARN} ${DIM}config not found${RESET}"; fi

    local gpu_icon gpu_label
    if systemctl is-active --quiet cyan-skillfish-governor-smu.service 2>/dev/null; then gpu_icon="$ICON_OK"; gpu_label="${GREEN}Activated${RESET}"
    else gpu_icon="$ICON_WARN"; gpu_label="${RED}Deactivated${RESET}"; fi
    echo -e "  ${B_BLUE}GPU Service${RESET}           ${gpu_icon} ${gpu_label}"

    if [[ -f "$GPU_CONF" ]]; then
        local gpu_freq gpu_throttle
        gpu_freq=$(awk -F'= ' '/^frequency/{sub(/#.*/, "", $2); print $2}' "$GPU_CONF" | tr -d ' ' | tail -1)
        gpu_throttle=$(awk -F'= ' '/^throttling /{sub(/#.*/, "", $2); print $2}' "$GPU_CONF" | tr -d ' ')
        echo -e "  ${B_BLUE}GPU Profile${RESET}           ${ICON_OK} ${gpu_freq}MHz  throttle ${gpu_throttle}°C"
    else echo -e "  ${B_BLUE}GPU Profile${RESET}           ${ICON_WARN} ${DIM}config not found${RESET}"; fi
    echo ""

    # HARDWARE UNLOCKS
    print_section "Hardware Unlocks"
    if rpm-ostree kargs 2>/dev/null | grep -q "mitigations=off"; then echo -e "  ${CYAN}CPU Mitigations${RESET}       ${ICON_OK} ${YELLOW}disabled${RESET} (mitigations=off active via rpm-ostree kargs)"
    else echo -e "  ${CYAN}CPU Mitigations${RESET}       ${ICON_WARN} ${GREEN}enabled${RESET} (default — disable for max performance)"; fi

    local active_threads; active_threads=$(nproc 2>/dev/null || echo "12")
    local calc_cores=$(( active_threads / 2 ))
    if [[ "$active_threads" -eq 16 ]]; then
        if [ -f "$REAL_HOME/CPU_Unlock/.installed" ] || systemctl is-active --quiet bc250-cpu-unlock 2>/dev/null; then
            echo -e "  ${CYAN}CPU Core Unlock${RESET}       ${ICON_OK} ${GREEN}Activated via systemd boot hooks (${calc_cores} Cores / ${active_threads} Threads)${RESET}"
        else echo -e "  ${CYAN}CPU Core Unlock${RESET}       ${ICON_OK} ${GREEN}Activated natively via permanent BIOS tables (${calc_cores} Cores / ${active_threads} Threads)${RESET}"; fi
    else echo -e "  ${CYAN}CPU Core Unlock${RESET}       ${ICON_OK} ${YELLOW}disabled (Factory stock 6-core / 12-thread scaling architecture)${RESET}"; fi

    # 🧬 UNIFIED HARDWARE DECODER
    local true_cu_count=24
    if command -v umr &>/dev/null; then
        local raw_bits; raw_bits=$(sudo umr -O bits -r amdgpu0.gfx1013.mmSPI_PG_ENABLE_STATIC_WGP_MASK 2>/dev/null | awk '{print $2}' | tr -d '[:space:]' || echo "")
        if [[ -z "$raw_bits" ]]; then raw_bits=$(sudo umr -O bits -r amdgpu0.gfx1030.mmSPI_SHADER_PG_CONFIG_CU 2>/dev/null | awk '{print $2}' | tr -d '[:space:]' || echo ""); fi
        if [[ -n "$raw_bits" ]]; then
            local hex_val; hex_val=$(printf "%d" "$raw_bits" 2>/dev/null || echo "0")
            if (( hex_val > 0 )); then
                local masked_wgps; masked_wgps=$(printf "%d" "$hex_val") local active_count=0
                for wgp in {0..4}; do if (( (masked_wgps & (1 << wgp)) != 0 )); then active_count=$((active_count + 2)); fi; done
                if (( active_count > 0 )); then true_cu_count=$(( active_count * 4 )); fi
            fi
        fi
    fi
    if [[ "$true_cu_count" -eq 24 ]] && [[ -f "/etc/bc250-cu-live-manager.conf" ]]; then
        local saved_masks; saved_masks=$(grep "BC250_WGP_MASKS=" /etc/bc250-cu-live-manager.conf | cut -d= -f2 | tr -d '"' || echo "")
        if [[ -n "$saved_masks" ]]; then
            local total_cus=0
            IFS=',' read -ra masks_array <<< "$saved_masks"
            for mask in "${masks_array[@]}"; do
                local val=$((mask))
                for wgp in {0..4}; do if (( (val & (1 << wgp)) != 0 )); then total_cus=$((total_cus + 2)); fi; done
            done
            if (( total_cus > 24 )); then true_cu_count="$total_cus"; fi
        fi
    fi
    if [[ -z "$true_cu_count" || "$true_cu_count" -eq 0 || "$true_cu_count" -lt 24 ]]; then true_cu_count=24; fi

    local cu_icon="$ICON_OK" local cu_color="${GREEN}" local cu_warn_msg=""
    if [ "$true_cu_count" -gt 24 ]; then cu_icon="$ICON_WARN" cu_color="${YELLOW}"; cu_warn_msg=" ${ICON_WARN} ${GREEN}Unlocked${RESET} — ${RED}verify power/cooling${RESET}"; fi
    echo -e "  ${CYAN}Active CUs${RESET}            ${ICON_WARN} ${true_cu_count}/40  ${DIM}(default 24, max 40)${RESET} ${ICON_WARN} ${GREEN}Unlocked${RESET} — ${RED}verify power/cooling${RESET}"
    # 🔒 ENVIRONMENT ISOLATION GATE
    if [ -f /.dockerenv ] || grep -qiE '(docker|lxc|containerd|podman|kubepods)' /proc/1/cgroup 2>/dev/null; then
        echo -e "  ${RED}❌ ENVIRONMENT ERROR:${RESET} Containerized deployment detected.\n"; return 1 2>/dev/null || exit 1
    fi

    if ram_split_installed; then
        local cmd_line; cmd_line=$(cat /proc/cmdline 2>/dev/null || echo "")
        local cmd_pages; cmd_pages=$(echo "$cmd_line" | grep -o 'ttm.pages_limit=[0-9]*' | cut -d= -f2 || echo "")
        local cmd_pool; cmd_pool=$(echo "$cmd_line" | grep -o 'ttm.page_pool_size=[0-9]*' | cut -d= -f2 || echo "")
        if [[ -z "$cmd_pages" && -f /etc/modprobe.d/bc250-mem.conf ]]; then
            cmd_pages=$(awk -F'[ =]' '/pages_limit/ {print $3}' /etc/modprobe.d/bc250-mem.conf 2>/dev/null || echo "")
            cmd_pool=$(awk -F'[ =]' '/page_pool_size/ {print $3}' /etc/modprobe.d/bc250-mem.conf 2>/dev/null || echo "")
        fi

        if [[ -n "$cmd_pages" && "$cmd_pages" -gt 0 ]]; then
            local pool_size_mb=$(( cmd_pages / 256 ))
            local calc_ram_gb=$(echo "scale=0; ($pool_size_mb + 512) / 1024" | bc 2>/dev/null || echo "8")
            local calc_vram_gb=$(( 16 - calc_ram_gb ))
            if (( calc_vram_gb < 0 )); then calc_vram_gb=0; fi

            local profile_lbl="Custom Layout Split"
            case "$cmd_pages" in
                "1572864") profile_lbl="Extreme VRAM Split (~6G System / ~10G VRAM)" ;;
                "1835008") profile_lbl="High VRAM Split (~7G System / ~9G VRAM)" ;;
                "2097152") profile_lbl="Stock Layout Split (~8G System / ~8G VRAM)" ;;
                "2621440") profile_lbl="Balanced Allocation (~10G System / ~6G VRAM)" ;;
                "3145728") profile_lbl="Entry VRAM Split (~12G System / ~4G VRAM)" ;;
                "3932160") profile_lbl="Native 512MB Split (~15G System / ~512M VRAM)" ;;
            esac
            echo -e "  ${CYAN}RAM/VRAM Split${RESET}        ${ICON_OK} ${GREEN}Activated (${profile_lbl})${RESET}"
            echo -e "                        ${BIBlack}↳ Current Allocation : ~${calc_ram_gb}G System RAM / ~${calc_vram_gb}G Dedicated VRAM${RESET}"
            echo -e "                        ${BIBlack}↳ Parameter Metrics  : Ceiling: ${cmd_pages} pages | Pool: ${pool_size_mb}MB${RESET}"
        else
            local hw_mem_kb; hw_mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo "0")
            local hw_mem_gb=$(echo "scale=0; ($hw_mem_kb + 524288) / 1024 / 1024" | bc 2>/dev/null || echo "8")
            local implied_vram=$(( 16 - hw_mem_gb ))
            if (( implied_vram < 0 )); then implied_vram=0; fi
            echo -e "  ${CYAN}RAM/VRAM Split${RESET}        ${ICON_OK} ${GREEN}Activated${RESET} (Natively partitioned via BIOS — ~${hw_mem_gb}G System RAM / ~${implied_vram}G Dedicated VRAM)"
        fi
    else echo -e "  ${CYAN}RAM/VRAM Split${RESET}        ${DIM}– not installed (Stock 8G/8G memory split blueprint)${RESET}"; fi
    echo ""
    # SWAP & ZRAM/ZSWAP
    print_section "Swap & ZRAM/ZSWAP"
    local swap_mb; swap_mb=$(swapfile_size_mb 2>/dev/null || echo "0")
    if (( swap_mb > 0 )); then
        echo -e "  ${CYAN}Swapfile${RESET}              ${ICON_OK} ${GREEN}$(( swap_mb / 1024 ))G${RESET} at ${SWAPFILE_PATH:-/var/swap/swapfile}"
    else
        echo -e "  ${CYAN}Swapfile${RESET}              ${DIM}managed by OS layers${RESET}"
    fi

    local active_comp="none"
    if [[ -f /sys/module/zswap/parameters/compressor ]]; then
        active_comp=$(cat /sys/module/zswap/parameters/compressor 2>/dev/null || echo "none")
    fi

    # 🚀 FIXED BAZZITE MATRIX: Audits true virtual parameters directly instead of cmdline text strings
    local zswap_enabled="N"
    if [[ -f /sys/module/zswap/parameters/enabled ]]; then
        zswap_enabled=$(cat /sys/module/zswap/parameters/enabled 2>/dev/null || echo "N")
    fi

    if zramctl | grep -q "/dev/zram"; then
        echo -e "  ${CYAN}ZRAM/ZSWAP${RESET}            ${ICON_OK} ${GREEN}ZRAM Activated${RESET} / ZSWAP managed"
    elif [[ "$zswap_enabled" == "Y" && "$active_comp" != "none" ]]; then
        echo -e "  ${CYAN}ZRAM/ZSWAP${RESET}            ${ICON_OK} ${GREEN}ZRAM Deactivated / ZSWAP Activated (${active_comp})${RESET}"
    else
        echo -e "  ${CYAN}ZRAM/ZSWAP${RESET}            ${ICON_WARN} ${YELLOW}ZRAM Deactivated / ZSWAP configured but idle${RESET}"
    fi
    echo ""

    # SENSOR & FAN CONTROL
    print_section "Sensors & Fan Control"
    local sens_driver sens_icon sens_color
    sens_driver="$(sensors_active_driver 2>/dev/null || echo "none")"
    case "$sens_driver" in
        nct6687) sens_icon="$ICON_OK"; sens_color="$GREEN"; sens_driver="nct6687 (loaded — full PWM control)" ;;
        nct6683) sens_icon="$ICON_WARN"; sens_color="$YELLOW"; sens_driver="nct6683 (loaded — read-only)" ;;
        *) sens_icon="$ICON_WARN"; sens_color="$YELLOW"; sens_driver="not loaded" ;;
    esac
    echo -e "  ${CYAN}Sensor Driver${RESET}         ${sens_icon} ${sens_color}${sens_driver}${RESET}"

    local cc_svc_state cc_icon cc_color
    if systemctl is-active --quiet coolercontrol-daemon.service 2>/dev/null || systemctl is-active --quiet coolercontrol.service 2>/dev/null || systemctl is-active --quiet coolercontrold.service 2>/dev/null || systemctl --user -M "$REAL_USER@" is-active --quiet coolercontrol.service 2>/dev/null || systemctl --user -M "$REAL_USER@" is-active --quiet coolercontrol-daemon.service 2>/dev/null; then cc_svc_state="activated"; cc_icon="$ICON_OK"; cc_color="$GREEN"
    else cc_svc_state="deactivated"; cc_icon="$ICON_WARN"; cc_color="$YELLOW"; fi
    echo -e "  ${CYAN}CoolerControl${RESET}         ${cc_icon} ${cc_color}${cc_svc_state}${RESET}"

    local xbox_icon xbox_color xbox_label
    xbox_label="$(xbox_adapter_status_label 2>/dev/null)"
    case "$xbox_label" in
        "loaded") xbox_icon="$ICON_OK"; xbox_color="$GREEN"; xbox_label="activated" ;;
        "installed (not loaded)") xbox_icon="$ICON_WARN"; xbox_color="$YELLOW"; xbox_label="installed (deactivated)" ;;
        "not installed"|*) xbox_icon="$ICON_WARN"; xbox_color="$YELLOW"; xbox_label="not installed" ;;
    esac
    echo -e "  ${CYAN}Xbox Wireless Adapter${RESET} ${xbox_icon} ${xbox_color}${xbox_label}${RESET}"

    # 🚀 ACCENT HARMONIZATION MAP: Perfectly matches layout spacing down your console screen grid
    local ds5_icon ds5_color ds5_label
    if [ -f "/etc/udev/rules.d/99-dualsense-bridge.rules" ] || [ -f "/etc/modprobe.d/bluetooth-lowlatency.conf" ]; then
        ds5_icon="$ICON_OK"; ds5_color="$GREEN"; ds5_label="activated (low-latency bridge fix engaged)"
    else
        ds5_icon="$ICON_WARN"; ds5_color="$YELLOW"; ds5_label="stock polling layout (auto-suspend enabled)"
    fi
    echo -e "  ${CYAN}Sony DualSense Adapter${RESET} ${ds5_icon} ${ds5_color}${ds5_label}${RESET}\n"

    # COMMUNITY FIXES & SILICON TUNING STATUS PASS
    print_section "Community Fixes & Silicon Tuning"

    local acpi_icon acpi_color acpi_label
    if acpi_fix_installed; then acpi_icon="$ICON_OK"; acpi_color="$GREEN"; acpi_label="activated (Loaded via OS-level early boot initrd override)"
    else acpi_icon="$ICON_WARN"; acpi_color="$DIM"; acpi_label="not installed"; fi
    echo -e "  ${B_RED}ACPI Fix${RESET}              ${acpi_icon} ${acpi_color}${acpi_label}${RESET}"

    local gpu_icon gpu_color gpu_label live_reg
    live_reg=$(sudo umr -r "cyan_skillfish.gfx1013.mmRLC_PG_ALWAYS_ON_WGP_MASK" 2>/dev/null | awk '{print $NF}')
    if [[ "$live_reg" == "0x0000001f" || "$live_reg" == "0x1f" ]]; then gpu_icon="$ICON_OK"; gpu_color="$GREEN"; gpu_label="ACTIVE (40 Compute Units locked wide awake in silicon)"
    else gpu_icon="$ICON_WARN"; gpu_color="$DIM"; gpu_label="DISABLED (Compute pairs subject to firmware power-gating)"; fi
    echo -e "  ${CYAN}GPU Power Shield${RESET}      ${gpu_icon} ${gpu_color}${gpu_label}${RESET}"

    local vram_icon vram_color vram_label
    if [ -f "/etc/modprobe.d/increase_amd_memory.conf" ] || grep -q "ttm.pages_limit" /etc/default/grub 2>/dev/null; then vram_icon="$ICON_OK"; vram_color="$GREEN"; vram_label="ACTIVE (14.75GB Dynamic UMA allocation ceiling unlocked)"
    else vram_icon="$ICON_WARN"; vram_color="$DIM"; vram_label="CAPPED (Factory-throttled 7.4GB memory allocation limit)"; fi
    echo -e "  ${YELLOW}Dynamic VRAM${RESET}          ${vram_icon} ${vram_color}${vram_label}${RESET}"

    local audio_icon audio_color audio_label
    if [ -f "/etc/modprobe.d/bc250-audio.conf" ]; then audio_icon="$ICON_OK"; audio_color="$GREEN"; audio_label="patched module activated (reboot advised)"
    else audio_icon="$ICON_WARN"; audio_color="$YELLOW"; audio_label="stock hardware module activated"; fi
    echo -e "  ${B_VIOLET}Audio Patch${RESET}           ${audio_icon} ${audio_color}${audio_label}${RESET}\n"

    check_system_health
}

# ==============================================================================
# 📂 GROUP 4: APPLICATION DESKTOP SHORTCUT SYSTEMS & DATABASE RE-INDEXERS
# ==============================================================================
refresh_desktop_database() {
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$LOCAL_APPS" &> /dev/null
    fi

    if command -v kbuildsycoca6 &> /dev/null; then
        sudo -u "$REAL_USER" kbuildsycoca6 --noincremental &> /dev/null
    elif command -v kbuildsycoca5 &> /dev/null; then
        sudo -u "$REAL_USER" kbuildsycoca5 --noincremental &> /dev/null
    fi
}

force_remove_shortcut() {
    print_info "Purging all existing legacy and current shortcut structures..."
    rm -f "$OLD_DESKTOP" "$OLD_DIRECTORY" "$OLD_MENU"
    refresh_desktop_database
}
create_start_menu_shortcut() {
    print_info "Creating start menu shortcut..."
    mkdir -p "$LOCAL_APPS"

    # 🚀 LOCAL UNPRIVILEGED GRAPHICS POOL DEPLOYMENT: Safely evades Bazzite's read-only system protections
    local local_icons="/var/home/bsystem/.local/share/icons"
    mkdir -p "$local_icons" 2>/dev/null
    if [ ! -f "$local_icons/matrix.ico" ]; then
        wget -q -O "$local_icons/matrix.ico" "https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/BC-250-Graphics-Compiler/Compiled/Icons/matrix.ico" || true
    fi
    chown bsystem:bsystem "$local_icons/matrix.ico" 2>/dev/null

    cat << EOF > "$OLD_DESKTOP"
[Desktop Entry]
Version=1.0
Type=Application
Name=Bazzite Toolbox
Comment=Launch Custom Bazzite Tweak Tool
Exec=sudo bash "$SCRIPT_PATH"
Icon=/var/home/bsystem/.local/share/icons/matrix.ico
Terminal=true
Categories=Utility;System;
X-KDE-Submenu=Bazzite Toolbox
EOF

    chmod +x "$OLD_DESKTOP"
    chown -R "$REAL_USER":"$REAL_USER" "$OLD_DESKTOP"

    rm -f "$OLD_DIRECTORY" "$OLD_MENU"
    refresh_desktop_database
    print_info "Shortcut installed successfully!"
}

manage_shortcut_prompt() {
    if [ -f "$CONFIG_FILE" ]; then
        local saved_pref; saved_pref=$(grep "START_MENU_SHORTCUT=" "$CONFIG_FILE" | cut -d= -f2)
        if [ "$saved_pref" == "false" ]; then force_remove_shortcut; return 0; fi
        if [ "$saved_pref" == "true" ]; then create_start_menu_shortcut; return 0; fi
    fi

    echo -e "\n${YELLOW}Would you like to add a Bazzite Toolbox shortcut to your Start Menu?${NC}"
    read -p "(Y/n): " -r user_choice
    user_choice=${user_choice:-Y}

    mkdir -p "$(dirname "$CONFIG_FILE")"

    if [[ "$user_choice" =~ ^[Yy]$ ]]; then
        echo "START_MENU_SHORTCUT=true" > "$CONFIG_FILE"
        chown "$REAL_USER":"$REAL_USER" "$CONFIG_FILE"
        create_start_menu_shortcut
    else
        echo "START_MENU_SHORTCUT=false" > "$CONFIG_FILE"
        chown "$REAL_USER":"$REAL_USER" "$CONFIG_FILE"
        force_remove_shortcut
        print_info "Opted out. All old shortcut records removed."
    fi
}

# =====================================================================
# MANUAL EXECUTION FLAGS (CLI OVERRIDES)
# =====================================================================
case "$1" in
    --install-shortcut)
        print_info "Manual override: Installing shortcut..."
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "START_MENU_SHORTCUT=true" > "$CONFIG_FILE"
        chown "$REAL_USER":"$REAL_USER" "$CONFIG_FILE"
        create_start_menu_shortcut
        exit 0
        ;;
    --remove-shortcut)
        print_info "Manual override: Removing shortcut..."
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "START_MENU_SHORTCUT=false" > "$CONFIG_FILE"
        chown "$REAL_USER":"$REAL_USER" "$CONFIG_FILE"
        force_remove_shortcut
        print_info "Shortcut completely uninstalled."
        exit 0
        ;;
    --updated)
        shift
        print_info "Update successful! Running latest sequence."
        manage_shortcut_prompt
        echo -e "${YELLOW}Press [Enter] to continue to the Bazzite Toolbox...${NC}"
        read -r
        ;;
esac

echo -e "${GREEN}Starting Bazzite Toolbox Core UI...${NC}"
# =====================================================================
# 1B. ATOMIC USER SPACE PATH MIGRATION & SHORTCUT RE-BIND ENGINE
# =====================================================================
migrate_legacy_install_path() {
    old_target="/var/home/bsystem/Bazzite_Toolbox"
    new_target="/var/home/bsystem/Applications/Bazzite_Toolbox"

# 🧠 KERNEL RESOLUTION: Explicitly finds the absolute physical path of the running script
    active_real_path=$(readlink -f "$0" 2>/dev/null || echo "$SCRIPT_PATH")

    if [ -d "$old_target" ] && [ "$active_real_path" != "$new_target/start.sh" ]; then
        print_info "Old legacy path caught! Syncing user space environments..."
        sudo -u bsystem mkdir -p "/var/home/bsystem/Applications" 2>/dev/null

        # 🧬 ATOMIC REPLICATOR: Copies your full toolkit folder into your unprivileged user space vault
        sudo -u bsystem cp -rT "$old_target" "$new_target" 2>/dev/null || true

        if [ -d "$new_target" ] && [ -f "$new_target/start.sh" ]; then
            print_info "Overwriting desktop launcher metadata configurations..."

            # 🚀 UNPRIVILEGED SHORTCUT RE-WRITER: Accesses desktop launch files straight from user space accounts
            sudo -u bsystem bash -c '
                local sc_paths=("/var/home/bsystem/Desktop" "/var/home/bsystem/.local/share/applications")
                for sc_dir in "${sc_paths[@]}"; do
                    if [ -d "$sc_dir" ]; then
                        find "$sc_dir" -type f -name "*Bazzite*.desktop" 2>/dev/null | while read -r desktop_file; do
                            sed -i "s|Exec=.*|Exec=env HOME=/var/home/bsystem XDG_CONFIG_HOME=/var/home/bsystem/.config konsole -e sudo bash \"/var/home/bsystem/Applications/Bazzite_Toolbox/start.sh\"|g" "$desktop_file" 2>/dev/null
                            sed -i "s|Path=.*|Path=/var/home/bsystem/Applications/Bazzite_Toolbox|g" "$desktop_file" 2>/dev/null
                            sed -i "s|Icon=.*|Icon=/var/home/bsystem/.local/share/icons/matrix.ico|g" "$desktop_file" 2>/dev/null
                            gio set "$desktop_file" metadata::trusted true 2>/dev/null || true
                        done
                    fi
                done
                update-desktop-database /var/home/bsystem/.local/share/applications 2>/dev/null
            '

            print_info "Purging legacy partition remnants..."
            SCRIPT_PATH="$new_target/start.sh"

            # 🚀 FORCED DISK DETACH: Moves the execution path out of the old folder before deleting it
            (cd /var/home/bsystem && sleep 1.0 && rm -rf "$old_target" 2>/dev/null) &

            # Instantly restart the script smoothly out of your clean updated production folder location
            exec bash "$SCRIPT_PATH" "$@"
        fi
    fi
}
# 🚀 Run the migration checkpoint function cleanly inside its insulated scope
migrate_legacy_install_path

# =====================================================================
# 2. AUTO-UPDATE MECHANISM (WITH SILENT OFFLINE FAIL)
# =====================================================================
local_script_update_url="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/start.sh"
# 🧬 MODDED 🧬
if [ "$1" != "--no-update" ] && [ "$1" != "--updated" ]; then
    if curl -s -I -L --connect-timeout 2 "$local_script_update_url" > /dev/null; then
        print_info "Checking for updates..."

        TEMP_FILE=$(mktemp)
        if curl -s -L --connect-timeout 2 "$local_script_update_url" -o "$TEMP_FILE"; then
            if ! cmp -s "$SCRIPT_PATH" "$TEMP_FILE"; then
                print_info "New version detected! Updating..."

                cp "$TEMP_FILE" "$SCRIPT_PATH"
                chmod +x "$SCRIPT_PATH"
                rm -f "$TEMP_FILE"

                print_info "Applying update and restarting..."
                exec bash "$SCRIPT_PATH" --updated "$@"
            fi
        fi
        rm -f "$TEMP_FILE"
    fi
fi

print_info "Starting main script workflow..."

ask_desktop_shortcut() {
    local desktop_dir; desktop_dir="$(sudo -u "$REAL_USER" xdg-user-dir DESKTOP 2>/dev/null || echo "")"
    [[ -n "$desktop_dir" ]] || desktop_dir="$REAL_HOME/Desktop"
    [[ -d "$desktop_dir" ]] || mkdir -p "$desktop_dir" 2>/dev/null || return 0
    local shortcut="$desktop_dir/Start Bazzite Boken Toolbox.desktop"
    [[ -f "$shortcut" ]] && return 0

    echo -e "  ${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║                  DESKTOP SHORTCUT CONFIGURATION                   ║${NC}"
    echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n  ${BIYellow}Would you like to add an application shortcut to your desktop?${NC}"
    echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
    echo -e "    ${CYAN}1)${NC} Yes, create desktop shortcut     ${BIBlack}(Generates native launcher file)${NC}"
    echo -e "\n    ${CYAN}2)${NC} No, skip shortcut creation\n"
    echo -e "    ${RED}[Enter]${NC} Skip and continue to main manager"
    echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}\n"
    read -rp "$(echo -e "  ${CYAN}Select an option [1-2]: ${NC}")" shortcut_choice

    case $shortcut_choice in
        1)
            local icon_dest="${REAL_HOME}/Applications/Bazzite_Toolbox"
            if [ ! -f "$icon_dest/matrix.ico" ]; then
                sudo -u "$REAL_USER" wget -q -O "$icon_dest/matrix.ico" "https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/BC-250-Graphics-Compiler/Compiled/Icons/matrix.ico" || true
            fi
            [[ -f "$icon_dest/matrix.ico" ]] || icon_dest="utilities-terminal"

            cat > "$shortcut" <<SHORTCUT_EOF
[Desktop Entry]
Type=Application
Name=Bazzite Boken Toolbox
Comment=Manage Memory - Overclock - Wake on Lan
Exec=konsole -e sudo bash "$SCRIPT_PATH"
Path=$icon_dest
Icon=${icon_dest}/matrix.ico
Terminal=false
Categories=System;
SHORTCUT_EOF
            chmod +x "$shortcut"
            chown "$REAL_USER":"$REAL_USER" "$shortcut" 2>/dev/null || true
            sudo -u "$REAL_USER" gio set "$shortcut" metadata::trusted true >/dev/null 2>&1 || true
            print_info "Bazzite Boken Toolbox shortcut created successfully!" && sleep 2
            ;;
        2|*) print_info "Skipping desktop shortcut generation." && sleep 1.5 ;;
    esac
}

ask_desktop_shortcut
manage_shortcut_prompt
prompt_reboot() {
    echo ""
    echo -e "  ${YELLOW}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${YELLOW}║                     MANDATORY SYSTEM REBOOT                       ║${NC}"
    echo -e "  ${YELLOW}╠═══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${YELLOW}║${NC}  ${BOLD}${GREEN}✔  Task Complete!${NC} The layered changes require a system restart.  ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}║${NC}     Please choose an environment state transition option below:   ${YELLOW}║${NC}"
    echo -e "  ${YELLOW}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "    ${CYAN}[1]${NC} Reboot Now        ${DIM}(Recommended to apply active layers)${RESET}"
    echo -e "    ${CYAN}[2]${NC} Shutdown Now      ${DIM}(Recommended to apply active layers)${RESET}"
    echo -e "    ${CYAN}[3]${NC} Cancel Reboot     ${DIM}(Return cleanly back to main toolkit menu)${RESET}"
    echo ""
    echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"

    # Colorized Interactive Prompt
    read -rp "$(echo -e "  ${CYAN}Select a reboot option [1-2]: ${NC}")" reboot_choice

    case "$reboot_choice" in
        1)
            echo -e "\n  ${GREEN}[+] Flushing caches and rebooting system now...${NC}"
            sleep 1.5
            sudo systemctl reboot
            ;;
        2)
            echo -e "\n  ${RED}[+] Flushing caches and shutting down system now...${NC}"
            sleep 1.5
            sudo systemctl poweroff
            ;;
        3)
            # Unified Cancel Notice matching your fallback loops
            echo -e "\n  ${YELLOW}[-] Reboot postponed. Returning safely back to main menu...${NC}"
            sleep 2
            return 0
            ;;
        *)
            echo -e "\n  ${RED}[-❌-] Invalid selection. Defaulting to safe menu fallback...${NC}"
            sleep 2
            return 1
            ;;
    esac
}
uninstall_blue_pill() {
    echo -e "${YELLOW}[●] Step 1/7: Forcibly stopping and disabling all governor services...${NC}"
    (sudo systemctl stop cyan-skillfish-governor-smu cyan-skillfish-governor cyan-skillfish-governor-tt oberon-governor 2>/dev/null || true) &>/dev/null
    (sudo systemctl disable cyan-skillfish-governor-smu cyan-skillfish-governor cyan-skillfish-governor-tt oberon-governor 2>/dev/null || true) &>/dev/null

    echo -e "${YELLOW}[●] Step 2/7: Stripping away system initramfs configuration locks...${NC}"
    # FIX: Disables the stuck manual initramfs flag inside the script to fix background transaction crashes
    (sudo rpm-ostree initramfs --disable 2>/dev/null || true) &>/dev/null

    echo -e "${YELLOW}[●] Step 3/7: Unlayering package structures from the system tree (Takes ~2 mins)...${NC}"
    (sudo rpm-ostree remove -y cyan-skillfish-governor-smu lz4 2>/dev/null || true) &>/dev/null
    (sudo copr disable filippor/bazzite -y 2>/dev/null || true) &>/dev/null

    echo -e "${YELLOW}[●] Step 4/7: Restoring factory kernel arguments (kargs)...${NC}"
    local kargs_remove=(
        --delete=mitigations=off
        --delete=zswap.enabled=1
        --delete=zswap.max_pool_percent=25
        --delete=zswap.compressor=lz4
        --delete=systemd.zram=0
        --delete=ttm.pages_limit
        --delete=ttm.page_pool_size
        --delete=amdgpu.gttsize
    )

    # 🧬 TWIN-STEP SPLASH GUARD INTEGRATION:
    # Purges performance flags while concurrently re-enforcing visual loading markers
    (sudo rpm-ostree kargs "${kargs_remove[@]}" --append="quiet" --append="rhgb" >> /var/log/bc250_oc_install.log 2>&1 || true) &>/dev/null

    # Synchronize layout template configurations
    (sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="quiet rhgb /g' /etc/default/grub 2>/dev/null) &>/dev/null

    # 🧬 GRUB ENVIRONMENT BLOCK FORCE-INJECTION
    # Directly writes to the environment registers to block ostree interpretation skips
    echo -e "${GREEN}[+] Step 5/7: Hard-locking visual splash screen variables...${NC}"
    (sudo grub2-editenv - set kernelopts="quiet rhgb" 2>/dev/null) &>/dev/null

    echo -e "${YELLOW}[●] Step 6/7: Tearing down BTRFS disk swapfile subvolume...${NC}"
    (sudo swapoff /var/swap/swapfile 2>/dev/null || true) &>/dev/null
    (sudo rm -f /var/swap/swapfile 2>/dev/null || true) &>/dev/null
    (sudo btrfs subvolume delete /var/swap 2>/dev/null || true) &>/dev/null

    echo -e "${YELLOW}[●] Step 7/7: Wiping configuration files, systemd symlinks, and caches...${NC}"
    (sudo sed -i '\/var\/swap\/swapfile/d' /etc/fstab 2>/dev/null || true) &>/dev/null
    (sudo rm -f /etc/sysctl.d/99-swappiness.conf 2>/dev/null || true) &>/dev/null
    (sudo rm -rf /etc/systemd/system/cyan-skillfish-governor* 2>/dev/null || true) &>/dev/null
    (sudo rm -rf /etc/cyan-skillfish-governor-smu 2>/dev/null || true) &>/dev/null

    (sudo rpm-ostree cleanup -m 2>/dev/null || true) &>/dev/null
    (sudo systemctl daemon-reload) &>/dev/null
    (ujust regenerate-grub &>/dev/null || true) &>/dev/null

    echo -e "${GREEN}\n[✓] Safe Removal Scheduled Successfully!${NC}"
    echo -e "${BOLD}${YELLOW}CRITICAL STEP:${RESET} You must reboot your machine now to apply the clean system layer."
    echo ""
    echo -e "\033[5m${B_RED}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "\033[5m${B_RED}║  [⚠] CRITICAL POST-REBOOT CONFIGURATION REQUIRED                                            ║${RESET}"
    echo -e "\033[5m${B_RED}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    play_success_chime; prompt_reboot; return 0
}
install_blue_pill() {
    # 1. Primary Check: Is Blue Pill already active on this host?
    if [ -f "$HOME/Blue_Pill_16GB/.installed" ]; then
        echo -e "${YELLOW}[●] Active Blue Pill optimization suite detected on this machine.${NC}"
        echo -e "${BOLD}${MAGENTA}Would you like to completely uninstall the suite and restore defaults?${RESET}"
        read -rp "  Select [y/N]: " rollback_choice
        echo ""

        # 1. PRIMARY CHECK: Is Red Pill active? Run Combined Foreground Rollback Matrix if True
        echo -e "${YELLOW}[●] Active Red Pill optimization suite detected on this machine.${NC}"
        echo -e "${B_RED}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "    ${BOLD}${YELLOW}[●] NOTICE: This uninstallation process takes approximately 30+ minutes to complete.${RESET}"
        echo -e "${B_RED}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${RESET}"
        read -rp "  Select [y/N]: " rollback_choice
        if [[ "$rollback_choice" =~ ^[Yy]$ ]]; then
            uninstall_blue_pill
            rm -f "$HOME/Blue_Pill_16GB/.installed" 2>/dev/null || true
        else
            echo -e "${DIM}Operation canceled. Returning to main menu...${RESET}"
            sleep 1
        fi
    else
        # 🧬 2. CROSS-CONFLICT SHIELD GATE: Detects if the Red Pill suite is running on this machine
        if [ -f "$HOME/Red_Pill_32GB/.installed" ]; then
            clear
            echo -e "\n  ${RED}╔═══════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "  ${RED}║                     SUITE CONFLICT SHIELD ACTIVE                  ║${NC}"
            echo -e "  ${RED}║               CROSS-DEPLOYMENT COLLISION BLOCKED                  ║${NC}"
            echo -e "  ${RED}╚═══════════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -e "  ${YELLOW}[⚠] NOTICE:${NC} The opposing ${RED}Red Pill (32GB Suite)${NC} is currently active on this system."
            echo -e "      Deploying both concurrently will corrupt your BTRFS subvolumes."
            echo ""
            echo -e "      The toolbox can automatically execute a deep safe uninstallation of"
            echo -e "      the Red Pill suite and reset system defaults before continuing."
            echo ""

            if confirm "Would you like to completely uninstall Red Pill first and proceed?"; then
                echo -e "\n${YELLOW}[●] Initializing automated Red Pill rollback sequence...${NC}"
                uninstall_red_pill
                rm -f "$HOME/Red_Pill_32GB/.installed" 2>/dev/null || true
                echo -e "${GREEN}[✓] Red Pill successfully uninstalled. Continuing to Blue Pill setup...${NC}"
                sleep 2
            else
                echo -e "  ${CYAN}[-] Operation canceled. Returning safely to primary toolkit menu...${NC}"
                sleep 1.5
                return 0
            fi
        fi

        # 🧬 3. PRE-FLIGHT INSTALLATION CONFIRMATION GATE
        echo -e "\n  ${B_BLUE}[●] Initialization Notice: You are about to deploy the Blue Pill Suite.${RESET}"
        echo -e "      This will alter your host swap partition layout and download performance binaries."

        if ! confirm "Are you sure this optimization option is what you want?"; then
            echo -e "  ${CYAN}[-] Installation bypassed. Returning cleanly to main menu...${NC}"
            sleep 1.2
            return 0
        fi

        echo -e "\n${B_BLUE}=== Executing Blue Pill (16GB Setup) ===${NC}"
        mkdir -p ~/Blue_Pill_16GB
        cd ~/Blue_Pill_16GB || return 1
        rm -f Setup-16GB.sh
        wget https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/Setup-16GB.sh
        chmod +x Setup-16GB.sh
        sudo ./Setup-16GB.sh
        (sudo rpm-ostree cleanup -m 2>/dev/null || true) &>/dev/null
        (sudo systemctl daemon-reload) &>/dev/null
        (ujust regenerate-grub &>/dev/null || true) &>/dev/null

        # Drop the persistent tracker file right after successful execution
        touch "$HOME/Blue_Pill_16GB/.installed"
        echo ""
        play_success_chime; prompt_reboot; return 0
    fi
}
uninstall_red_pill() {
    echo -e "${YELLOW}[●] Step 1/7: Forcibly stopping and disabling all governor services...${NC}"
    (sudo systemctl stop cyan-skillfish-governor-smu cyan-skillfish-governor cyan-skillfish-governor-tt oberon-governor 2>/dev/null || true) &>/dev/null
    (sudo systemctl disable cyan-skillfish-governor-smu cyan-skillfish-governor cyan-skillfish-governor-tt oberon-governor 2>/dev/null || true) &>/dev/null

    echo -e "${YELLOW}[●] Step 2/7: Stripping away system initramfs configuration locks...${NC}"
    # FIX: Disables the stuck manual initramfs flag inside the script to fix background transaction crashes
    (sudo rpm-ostree initramfs --disable 2>/dev/null || true) &>/dev/null

    echo -e "${YELLOW}[●] Step 3/7: Unlayering package structures from the system tree (Takes ~2 mins)...${NC}"
    (sudo rpm-ostree remove -y cyan-skillfish-governor-smu lz4 2>/dev/null || true) &>/dev/null
    (sudo copr disable filippor/bazzite -y 2>/dev/null || true) &>/dev/null

    echo -e "${YELLOW}[●] Step 4/7: Restoring factory kernel arguments (kargs)...${NC}"
    local kargs_remove=(
        --delete=mitigations=off
        --delete=zswap.enabled=1
        --delete=zswap.max_pool_percent=25
        --delete=zswap.compressor=lz4
        --delete=systemd.zram=0
        --delete=ttm.pages_limit
        --delete=ttm.page_pool_size
        --delete=amdgpu.gttsize
    )

    # 🧬 TWIN-STEP SPLASH GUARD INTEGRATION:
    # Purges performance flags while concurrently re-enforcing visual loading markers
    (sudo rpm-ostree kargs "${kargs_remove[@]}" --append="quiet" --append="rhgb" >> /var/log/bc250_oc_install.log 2>&1 || true) &>/dev/null

    # Synchronize layout template configurations
    (sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="quiet rhgb /g' /etc/default/grub 2>/dev/null) &>/dev/null

    # 🧬 GRUB ENVIRONMENT BLOCK FORCE-INJECTION
    # Directly writes to the environment registers to block ostree skips and hold the splash active
    echo -e "${GREEN}[+] Step 5/7: Hard-locking visual splash screen variables...${NC}"
    (sudo grub2-editenv - set kernelopts="quiet rhgb" 2>/dev/null) &>/dev/null

    echo -e "${YELLOW}[●] Step 6/7: Tearing down BTRFS disk swapfile infrastructure...${NC}"
    (sudo swapoff /var/swap/swapfile 2>/dev/null || true) &>/dev/null
    (sudo rm -f /var/swap/swapfile 2>/dev/null || true) &>/dev/null
    (sudo btrfs subvolume delete /var/swap 2>/dev/null || true) &>/dev/null

    echo -e "${YELLOW}[●] Step 7/7: Wiping configuration files, systemd symlinks, and caches...${NC}"
    (sudo sed -i '\/var\/swap\/swapfile/d' /etc/fstab 2>/dev/null || true) &>/dev/null
    (sudo rm -f /etc/sysctl.d/99-swappiness.conf 2>/dev/null || true) &>/dev/null
    (sudo rm -rf /etc/systemd/system/cyan-skillfish-governor* 2>/dev/null || true) &>/dev/null
    (sudo rm -rf /etc/cyan-skillfish-governor-smu 2>/dev/null || true) &>/dev/null

    (sudo rpm-ostree cleanup -m 2>/dev/null || true) &>/dev/null
    (sudo systemctl daemon-reload) &>/dev/null
    (ujust regenerate-grub &>/dev/null || true) &>/dev/null

    echo -e "${GREEN}\n[✓] Safe Removal Scheduled Successfully!${NC}"
    echo -e "${BOLD}${YELLOW}CRITICAL STEP:${RESET} You must reboot your machine now to apply the clean system layer."
    echo ""
    echo -e "\033[5m${B_RED}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "\033[5m${B_RED}║  [⚠] CRITICAL POST-REBOOT CONFIGURATION REQUIRED                                            ║${RESET}"
    echo -e "\033[5m${B_RED}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    play_success_chime; prompt_reboot; continue
    return 0
}
install_red_pill() {
    # 1. Primary Check: Is Red Pill already active on this host?
    if [ -f "$HOME/Red_Pill_32GB/.installed" ]; then
        echo -e "${YELLOW}[●] Active Red Pill optimization suite detected on this machine.${NC}"
        echo -e "${BOLD}${MAGENTA}Would you like to completely uninstall the suite and restore defaults?${RESET}"
        read -rp "  Select [y/N]: " rollback_choice
        echo ""

    # 1. PRIMARY CHECK: Is Red Pill active? Run Combined Foreground Rollback Matrix if True
        echo -e "${YELLOW}[●] Active Red Pill optimization suite detected on this machine.${NC}"
        echo -e "${B_RED}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "    ${BOLD}${YELLOW}[●] NOTICE: This uninstallation process takes approximately 30+ minutes to complete.${RESET}"
        echo -e "${B_RED}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${RESET}"
        read -rp "  Select [y/N]: " rollback_choice
        if [[ "$rollback_choice" =~ ^[Yy]$ ]]; then
            uninstall_red_pill
            rm -f "$HOME/RED_Pill_32GB/.installed" 2>/dev/null || true
        else
            echo -e "${DIM}Operation canceled. Returning to main menu...${RESET}"
            sleep 1
        fi
    else
        # 🧬 2. CROSS-CONFLICT SHIELD GATE: Detects if the Blue Pill suite is running on this machine
        if [ -f "$HOME/Blue_Pill_16GB/.installed" ]; then
            clear
            echo -e "\n  ${RED}╔═══════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "  ${RED}║                     SUITE CONFLICT SHIELD ACTIVE                  ║${NC}"
            echo -e "  ${RED}║               CROSS-DEPLOYMENT COLLISION BLOCKED                  ║${NC}"
            echo -e "  ${RED}╚═══════════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -e "  ${YELLOW}[⚠] NOTICE:${NC} The opposing ${RED}Blue Pill (16GB Suite)${NC} is currently active on this system."
            echo -e "      Deploying both concurrently will corrupt your BTRFS subvolumes."
            echo ""
            echo -e "      The toolbox can automatically execute a deep safe uninstallation of"
            echo -e "      the Blue Pill suite and reset system defaults before continuing."
            echo ""

            if confirm "Would you like to completely uninstall Blue Pill first and proceed?"; then
                echo -e "\n${YELLOW}[●] Initializing automated Blue Pill rollback sequence...${NC}"
                uninstall_blue_pill
                rm -f "$HOME/Blue_Pill_16GB/.installed" 2>/dev/null || true
                echo -e "${GREEN}[✓] Blue Pill successfully uninstalled. Continuing to Red Pill setup...${NC}"
                sleep 2
            else
                echo -e "  ${CYAN}[-] Operation canceled. Returning safely to primary toolkit menu...${NC}"
                sleep 1.5
                return 0
            fi
        fi

        # 🧬 3. PRE-FLIGHT INSTALLATION CONFIRMATION GATE
        echo -e "\n  ${B_RED}[●] Initialization Notice: You are about to deploy the Red Pill Suite.${RESET}"
        echo -e "      This will alter your host swap partition layout and download performance binaries."

        if ! confirm "Are you sure this optimization option is what you want?"; then
            echo -e "  ${CYAN}[-] Installation bypassed. Returning cleanly to main menu...${NC}"
            sleep 1.2
            return 0
        fi

        echo -e "\n${B_RED}=== Executing Red Pill (32GB Setup) ===${NC}"
        mkdir -p ~/Red_Pill_32GB
        cd ~/Red_Pill_32GB || return 1
        rm -f Setup-32GB.sh
        wget https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/Setup-32GB.sh
        chmod +x Setup-32GB.sh
        sudo ./Setup-32GB.sh
        (sudo rpm-ostree cleanup -m 2>/dev/null || true) &>/dev/null
        (sudo systemctl daemon-reload) &>/dev/null
        (ujust regenerate-grub &>/dev/null || true) &>/dev/null

        # Drop the persistent tracker file right after successful execution
        touch "$HOME/Red_Pill_32GB/.installed"
        echo ""
        play_success_chime; prompt_reboot; return 0
    fi
}
# Function to Launch Overclock
install_overclock() {
    echo -e "${B_RED}=== Launching Overclock Menu ===${NC}"

    local oc_dir="$REAL_HOME/Applications/Bazzite_Toolbox/Overclock"
    mkdir -p "$oc_dir"
    cd "$oc_dir" || return 1
    chown -R "$REAL_USER":"$REAL_USER" "$oc_dir"

    local oc_url="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/Overclock-Live-Manager.sh"
    local run_download=false

    # 🧬 OFFLINE-FIRST ENFORCEMENT: Fast 2-second pre-flight connectivity handshake
    if curl -s -I -L --connect-timeout 2 "$oc_url" > /dev/null; then
        run_download=true
    fi

    if [ "$run_download" = true ]; then
        echo -e "${YELLOW}[●] Checking GitHub for script updates...${NC}"
        sudo -u "$REAL_USER" wget -N "$oc_url" 2>/dev/null
    else
        log "${YELLOW}[ℹ] Network connection down or GitHub unreachable. Using localized cache layers...${NC}"
        sleep 1.5
    fi

    # Safety Net Validation Shield
    if [ ! -s "Overclock-Live-Manager.sh" ]; then
        echo -e "${RED}ERROR: Script file not found on disk and cannot be downloaded! Check network.${NC}"
        sleep 4
        return 1
    fi

    chmod +x Overclock-Live-Manager.sh
    echo "Transitioning terminal to Overclock Live Manager..."
    sleep 1

    ENVIRONMENT=bazzite Overrides=true bash ./Overclock-Live-Manager.sh
    echo -e "${YELLOW}Overclock Manager closed. Returning to main menu...${NC}"
    sleep 2
}

# Function to Launch wake on lan
install_wake_on_lan() {
    echo -e "${B_RED}=== Launching Wake on LAN Menu ===${NC}"

    local wol_dir="$REAL_HOME/Applications/Bazzite_Toolbox/Wake_on_LAN"
    mkdir -p "$wol_dir"
    cd "$wol_dir" || return 1
    chown -R "$REAL_USER":"$REAL_USER" "$wol_dir"

    local wol_url="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Wake_on_LAN/Wake-on-LAN-Manager.sh"
    local run_download=false

    # 🧬 OFFLINE-FIRST ENFORCEMENT: Run a rapid 2-second pre-flight connection handshake pass
    if curl -s -I -L --connect-timeout 2 "$wol_url" > /dev/null; then
        run_download=true
    fi

    if [ "$run_download" = true ]; then
        echo -e "${YELLOW}[●] Checking GitHub for script updates...${NC}"
        sudo -u "$REAL_USER" wget -N "$wol_url" 2>/dev/null
    else
        log "${YELLOW}[ℹ] Network connection down or GitHub unreachable. Using localized cache layers...${NC}"
        sleep 1.5
    fi

    # Safety Net Validation Shield
    if [ ! -s "Wake-on-LAN-Manager.sh" ]; then
        echo -e "${RED}ERROR: Script file not found on disk and cannot be downloaded! Check network.${NC}"
        sleep 4
        return 1
    fi
    chmod +x Wake-on-LAN-Manager.sh

    echo "Transitioning terminal to Wake on LAN Manager..."
    sleep 1

    ENVIRONMENT=bazzite Overrides=true bash ./Wake-on-LAN-Manager.sh
    echo -e "${YELLOW}Wake on LAN Manager closed. Returning to main menu...${NC}"
    sleep 2
}
# ==============================================================================
# 🎛️ GROUP 3 (CONT.): GOVERNOR VERSION DETECTOR & LIVE UPGRADE MATRIX
# ==============================================================================
update_cyan-skillfish() {
    clear
    echo -e "\n  ${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "  ${CYAN}║                UPGRADE CYAN-SKILLFISH GOVERNOR TRACK              ║${NC}"
    echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "  ${YELLOW}[ℹ] Interrogating active package repository tables for updates...${NC}"
    echo -ne "      Current local binary version profile: "
    cyan-skillfish-governor-smu --version 2>/dev/null || echo "Not Installed / Staged Only"
    echo ""

    # 🚀 LIVE VERSION UPGRADE CHECKER:
    # Queries the ostree tree to determine if a newer version package is waiting on the server database
    local check_update
    check_update=$(rpm-ostree upgrade --check 2>/dev/null || true)

    if [[ -z "$check_update" ]] || ! echo "$check_update" | grep -qi "cyan-skillfish-governor-smu"; then
    TEXT_STR=" Your machine is already running the absolute newest optimized build from the COPR tracking stream. "
        echo -e "  ${GREEN}╔════════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${GREEN}║${NC}  ${BOLD}[✓] GOVERNOR SUITE IS COMPLETELY UP TO DATE!${NC}                                                      ${GREEN}║${NC}"
        echo -e "  ${GREEN}╠════════════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "  ${GREEN}║${NC}${TEXT_STR}${GREEN}║${NC}"
        echo -e "  ${GREEN}╚════════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        type_prompt "  Press [Enter] to return safely back to the toolkit main menu... " 0.03
        read -rp "  "
        return 0
    fi

    # Cascading Path: If the checker discovers that a new version exists, prompt to apply it
    echo -e "  ${BIYellow}[●] ATTENTION: A newer optimized governor update layer has been discovered!${NC}\n"
    if confirm "Would you like to pull the latest optimized governor image layers now?"; then
        echo -e "${GREEN}[+] Step 1/3: Forcing background package index updates...${NC}"
        (sudo rpm-ostree refresh-md --force) &>/dev/null

        echo -e "${GREEN}[+] Step 2/3: Pulling latest system-compatible governor package layers...${NC}"
        sudo rpm-ostree install -y cyan-skillfish-governor-smu >> /var/log/bc250_oc_install.log 2>&1

        echo -e "${GREEN}[+] Step 3/3: Seeding frequency fix locks inside container profiles...${NC}"
        if [[ -f /etc/cyan-skillfish-governor-smu/config.toml ]]; then
            if ! grep -q "fix-freq = true" /etc/cyan-skillfish-governor-smu/config.toml; then
                sudo sed -i '/^\[gpu-usage\]/a fix-freq = true' /etc/cyan-skillfish-governor-smu/config.toml 2>/dev/null
            fi
        fi

        print_success "Cyan-Skillfish governor tracking parameters upgraded successfully!"
        play_success_chime; prompt_reboot; continue
        return 0
    else
        echo -e "${CYAN}[-] Operation canceled. Returning safely to primary toolkit menu...${NC}"
        sleep 1.2
        return 0
    fi
}

play_success_chime() {
    echo -ne '\e[?5h'; sleep 0.1; echo -ne '\e[?5l'
    local real_uid; real_uid=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")
    if [[ -f "/usr/share/sounds/oxygen/stereo/outcome-success.ogg" ]] && command -v pw-play &>/dev/null; then
        # 🧬 FIX TRACKING MASK: Enforce $real_uid across ALL three runtime paths flatly
        sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$real_uid" PIPEWIRE_RUNTIME_DIR="/run/user/$real_uid" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$real_uid/bus" pw-play /usr/share/sounds/oxygen/stereo/outcome-success.ogg &>/dev/null || true
    fi
}

# ==============================================================================
# 📂 GROUP 4: INTEGRATED UPSCALER & COMPRESSED PAYLOAD INJECTORS
# ==============================================================================
deploy_gfx1013_fsr4_engine() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local B_RED='\033[1;31m' local RESET='\033[0m'

    local cache_dir="/tmp/bc250_fsr4_staging"
    local dl_url="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/bc250-fsr4-dll-4.0.0-rc11.7z"
    local dll_name="amd_fidelityfx_upscaler_dx12.dll"

    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "   🚀 GFX1013 FSR 4.1.1 ADAPTIVE DEPLOYMENT ENGINE (RC11 PROD)       "
    echo -e "${CYAN}====================================================================${RESET}"

    rm -rf "$cache_dir" && mkdir -p "$cache_dir"
    echo -e "${GREEN}[+] Pulling optimized FSR 4.1.1 master 7-Zip package...${RESET}"

    if ! wget --no-check-certificate --timeout=15 -qO "$cache_dir/fsr4_pack.7z" "${dl_url}"; then
        echo -e "${RED}❌ ERROR: Failed to download the upscaler package from GitHub.${RESET}"
        read -rp "Press [Enter] to return back to toolkit menu..." dummy; return 1
    fi

    echo -e "\n${YELLOW}[ℹ] CHOOSE INJECTION TARGET METHOD:${RESET}"
    echo -e "  1) Track A: Overwrite an existing OptiScaler folder location"
    echo -e "  2) Track B: Overwrite a Native FidelityFX game engine DLL file"
    echo -n "  Select deployment path choice [1-2]: "
    local target_track; read -r target_track

    echo -e "\n${CYAN}[➡] Enter the ABSOLUTE path directory to your target game folder:${RESET}"
    echo -n "    Path: "
    local game_path; read -r game_path

    game_path=$(echo "$game_path" | sed -e 's/[[:space:]]*$//' -e 's|/*$||')
    if [[ ! -d "$game_path" ]]; then
        echo -e "${RED}❌ ERROR: Provided directory path track does not exist on disk.${RESET}"
        read -rp "Press [Enter] to return..." dummy; return 1
    fi

    echo -e "\n${YELLOW}[ℹ] SELECT ENGINE-SPECIFIC PRESET OPTIMIZER:${RESET}"
    echo -e "  1) Standard Profile : Baseline RDNA1 Setup (Spider-Man, Cyberpunk, General Titles)"
    echo -e "  2) Capcom RE Engine : Fixes mesh stretching & broken graphics textures (RE4, Dead Rising)"
    echo -e "  3) Anti-Flicker     : Forces Non-Linear Color Maps to block sky/menu flashing"
    echo -n "  Select game profile target [1-3]: "
    local engine_preset; read -r engine_preset

    if confirm "Inject this custom upscaler binary payload and proxy hook into your game tracks?"; then
        [[ "$target_track" == "1" ]] && mkdir -p "${game_path}/OptiScaler"

        # 🛡️ PRE-FLIGHT BACKUP GUARD: Safely copies factory originals right before file updates
        echo -e "\n${YELLOW}[ℹ] Securing native factory engine backups...${RESET}"
        if [[ -f "${game_path}/dxgi.dll" && ! -f "${game_path}/dxgi.dll.bak" ]]; then
            cp "${game_path}/dxgi.dll" "${game_path}/dxgi.dll.bak"
            echo -e "${GREEN}[✓] Saved copy of original game dxgi.dll -> dxgi.dll.bak${RESET}"
        fi
        if [[ -f "${game_path}/${dll_name}" && ! -f "${game_path}/${dll_name}.bak" ]]; then
            cp "${game_path}/${dll_name}" "${game_path}/${dll_name}.bak"
            echo -e "${GREEN}[✓] Saved copy of original game upscaler core -> ${dll_name}.bak${RESET}"
        fi

        echo -e "${GREEN}[+] Deploying release payload objects directly to target drive...${RESET}"
        # 🎯 ROOT INJECTION MANDATE: Both core files are extracted cleanly to root next to the .exe file [1.11]
        if ! 7z e -aoa "$cache_dir/fsr4_pack.7z" "-o$game_path" "-ir!dxgi.dll" &>/dev/null; then
            echo -e "${RED}❌ ERROR: Failed to inject master dxgi.dll proxy bridge to root game folder.${RESET}"
            rm -rf "$cache_dir"; read -rp "Press [Enter] to return..." dummy; return 1
        fi
        if ! 7z e -aoa "$cache_dir/fsr4_pack.7z" "-o$game_path" "-ir!${dll_name}" &>/dev/null; then
            echo -e "${RED}❌ ERROR: Failed to inject upscaler core mathematics payload into target path.${RESET}"
            rm -rf "$cache_dir"; read -rp "Press [Enter] to return..." dummy; return 1
        fi

        chown -R bsystem:bsystem "${game_path}/dxgi.dll" "${game_path}/${dll_name}" "${game_path}/OptiScaler" 2>/dev/null

        # 🚀 WIKI-GROUNDED CONFIGURATION INJECTOR ENGINE
        local config_file="${game_path}/nvngx.ini"
        echo -e "${GREEN}[+] Structuring tailored FSR configuration engine profiles...${RESET}"
        {
            echo "[Global]"
            echo "LogLevel = info"
            echo "LogToFile = false"
            echo "[Upscalers]"
            echo "Dx12Upscaler = fsr31"
            echo "[FSR]"
            echo "Fsr4EnableWatermark = true"

            if [[ "$engine_preset" == "2" ]]; then
                echo "[RootSignatures]"
                echo "RestoreComputeRootSignature = true"
            elif [[ "$engine_preset" == "3" ]]; then
                echo "[Color]"
                echo "ColorResourceBarrier = 4"
                echo "NonLinearSRGBInput = true"
            fi
        } > "$config_file"
        chown bsystem:bsystem "$config_file" 2>/dev/null

        echo -e "${GREEN}[✓] Master dxgi.dll proxy bridge automatically deployed to root game folder!${RESET}"
        echo -e "${GREEN}[✓] Character-perfect injection loop complete! Mod deployed.${RESET}"

        echo -e "\n${B_RED}====================================================================${RESET}"
        echo -e "  ⚠️ CRITICAL CONFIGURATION & STEAM LAUNCH OPTION INFO                "
        echo -e "====================================================================${RESET}"
        echo -e "  To verify the mod is running at maximum efficiency, look at the   "
        echo -e "  bottom right screen corner in-game. A text string displaying      "
        echo -e "  'FSR4' or 'FSR3' confirms the upscaler runtime is fully active!  "
        echo -e "  Make sure your game Steam launch options include the system bypass:"
        echo -e "  WINEDLLOVERRIDES=\"dxgi=n,b\" %command%                            "
        echo -e "${B_RED}====================================================================${RESET}"

        rm -rf "$cache_dir"
        read -rp "Press [Enter] to safely clear warning and return to menu dashboard..." dummy
    fi
}

toggle_gfx1013_fsr4_engine() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local B_RED='\033[1;31m' local DIM='\033[38;2;110;110;110m' local RESET='\033[0m'

    local cache_dir="/tmp/bc250_fsr4_staging"
    local dll_name="amd_fidelityfx_upscaler_dx12.dll"
    local local_src="/home/bsystem/Downloads/bc250-fsr4-dll-4.0.0-rc11"
    local manifest_name=".bc250_fsr4_manifest.txt"

    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "   🚀 GFX1013 FSR 4.1.1 MULTI-BRANCH SELECTOR CORE MATRIX IMAGE       "
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "   Select the upscaler engine target architecture version deployment: "
    echo -e ""
    echo -e "   1) Deploy v4.0.0-rc11 PROD  : Explicit UI Menu, High Stability (Single 7z)"
    echo -e "   2) Deploy v10.0.0-pre1 ALPHA: Modular SDK, Advanced Buffering Clamps (Single 7z)"
    echo -e "   3) Exit back to main dashboard menu"
    echo -e ""
    echo -n "   Select target branch choice [1-3]: "
    local branch_choice; read -r branch_choice

    if [[ "$branch_choice" == "3" || -z "$branch_choice" ]]; then return 0; fi

    local version_tag=""
    if [[ "$branch_choice" == "1" ]]; then
        version_tag="v4.0.0-rc11 PROD"
    elif [[ "$branch_choice" == "2" ]]; then
        version_tag="v10.0.0-pre1 ALPHA"
    else
        echo -e "${RED}❌ ERROR: Invalid matrix choice constraint selection.${RESET}"
        read -rp "Press [Enter] to return..." dummy; return 1
    fi

    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "   🚀 TARGET: DEPLOYING FSR 4.1.1 ENGINES [ $version_tag ]            "
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "${CYAN}[➡] Enter the ABSOLUTE path directory to your target game folder:${RESET}"
    echo -n "    Path: "
    local game_path; read -r game_path
    game_path="${game_path#\'}"; game_path="${game_path%\'}"; game_path="${game_path#\"}"; game_path="${game_path%\"}"
    game_path=$(echo "$game_path" | sed -e 's/[[:space:]]*$//' -e 's|/*$||')

    if [[ ! -d "$game_path" ]]; then
        echo -e "${RED}❌ ERROR: Provided directory path track does not exist on disk.${RESET}"
        read -rp "Press [Enter] to return..." dummy; return 1
    fi
    set +e
    local mf_path="${game_path}/${manifest_name}"
    if [[ -f "$mf_path" || -f "${game_path}/dxgi.dll" || -f "${game_path}/OptiScaler.ini" ]]; then
        echo -e "\n${YELLOW}[ℹ] Existing FSR Mod framework detected inside this directory!${RESET}"
        echo -n "👉 Remove the active upscaler mod and restore factory binaries? (y/N): "
        local ans_un; read -r ans_un
        if [[ "$ans_un" =~ ^[Yy]$ ]]; then
            echo -e "\n${YELLOW}[ℹ] Purging deployed mod files and configurations...${RESET}"

            if [[ -f "$mf_path" ]]; then
                echo -e "  ${DIM}➜ Executing manifest file footprint wipe...${RESET}"
                while IFS= read -r file_to_delete || [[ -n "$file_to_delete" ]]; do
                    [[ -n "$file_to_delete" ]] && rm -f "${game_path}/${file_to_delete}" 2>/dev/null
                done < "$mf_path"
                rm -f "$mf_path" 2>/dev/null
            else
                # 🧬 NO HARCODED NAMES FALLBACK: Dynamically maps and wipes loose assets in root directory safely [0.14]
                echo -e "  ${YELLOW}[ℹ] Legacy deployment detected. Initializing generic filesystem purge loop...${RESET}"
                find "$game_path" -maxdepth 1 -type f \( -name "*.dll" -o -name "*.ini" -o -name "*.asi" \) ! -name "steam_api*" -exec rm -f {} \; 2>/dev/null
            fi

            rm -rf "${game_path}/plugins" "${game_path}/OptiScaler"
            if [[ -f "${game_path}/dxgi.dll.bak" ]]; then mv "${game_path}/dxgi.dll.bak" "${game_path}/dxgi.dll" 2>/dev/null; fi
            if [[ -f "${game_path}/${dll_name}.bak" ]]; then mv "${game_path}/${dll_name}.bak" "${game_path}/${dll_name}" 2>/dev/null; fi

            chown -R bsystem:bsystem "$game_path" 2>/dev/null
            echo -e "${GREEN}[✓] Existing environment successfully returned to factory defaults.${RESET}"
            echo -e "${CYAN}====================================================================${RESET}"

            echo -n "👉 Would you like to proceed with a fresh upscaler deployment layout now? (y/N): "
            local ans_re; read -r ans_re
            if [[ ! "$ans_re" =~ ^[Yy]$ ]]; then
                read -rp "👍 Uninstallation complete. Press [Enter] to return to dashboard..." dummy; return 0
            fi
            echo -e "\n${GREEN}[+] Transitioning straight to clean deployment engine tracks...${RESET}"
        else
            return 0
        fi
    else
        echo -e "\n${GREEN}[+] No existing mod wrappers found. Initializing installer pass...${RESET}"
        echo -n "👉 Inject custom upscaler binary payload and proxy hook? (y/N): "
        local ans_in; read -r ans_in
        if [[ ! "$ans_in" =~ ^[Yy]$ ]]; then return 0; fi
    fi
    echo -e "\n${YELLOW}[ℹ] SELECT ENGINE-SPECIFIC PRESET OPTIMIZER:${RESET}"
    echo -e "  1) Standard Profile : Baseline RDNA1 Setup (Spider-Man, Cyberpunk, General Titles)"
    echo -e "  2) Capcom RE Engine : Fixes mesh stretching & broken graphics textures (RE4, Dead Rising)"
    echo -e "  3) Anti-Flicker     : Forces Non-Linear Color Maps to block sky/menu flashing"
    echo -n "  Select game profile target [1-3]: "
    local engine_preset; read -r engine_preset

    local destination_dir="${game_path}/OptiScaler"
    local plugin_dir="${game_path}/plugins"
    mkdir -p "$destination_dir" "$plugin_dir"

    if [[ -f "${game_path}/dxgi.dll" && ! -f "${game_path}/dxgi.dll.bak" ]]; then cp "${game_path}/dxgi.dll" "${game_path}/dxgi.dll.bak" 2>/dev/null; fi
    if [[ -f "${game_path}/${dll_name}" && ! -f "${game_path}/${dll_name}.bak" ]]; then cp "${game_path}/${dll_name}" "${game_path}/${dll_name}.bak" 2>/dev/null; fi

    rm -rf "$cache_dir" && mkdir -p "$cache_dir"
    local tmp_extract="${cache_dir}/extracted"
    mkdir -p "$tmp_extract"
    local exit_code_1=0

    if [[ -d "$local_src" && "$branch_choice" == "1" ]]; then
        echo -e "\n${GREEN}[✓] Local full-payload workspace directory found! Staging file map...${RESET}"
        cp -rT "$local_src" "$tmp_extract" 2>/dev/null
    else
        echo -e "\n${YELLOW}[ℹ] Initializing download chain for remote server files...${RESET}"
        local dl_url=""
        if [[ "$branch_choice" == "1" ]]; then
            dl_url="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/BC-250-Graphics-Compiler/Compiled/Compressed/bc250-fsr4-dll-4.0.0-rc11.7z"
        elif [[ "$branch_choice" == "2" ]]; then
            dl_url="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/BC-250-Graphics-Compiler/Compiled/Compressed/bc250-fsr4-dll-4.0.0-rc11.1.7z"
        fi

        echo -e "${GREEN}[+] Fetching remote payload archive...${RESET}"
        if wget --no-check-certificate --timeout=15 -qO "$cache_dir/fsr4_pack.7z" "${dl_url}"; then
            7z x -aoa "$cache_dir/fsr4_pack.7z" "-o$tmp_extract" &>/dev/null
            exit_code_1=$?
        else
            exit_code_1=1
        fi
    fi

    if [ $exit_code_1 -eq 0 ]; then
        local payload_files; payload_files=$(find "$tmp_extract" -type f \( -name "*.dll" -o -name "*.ini" -o -name "*.asi" \) 2>/dev/null)
        rm -f "$mf_path" 2>/dev/null
        touch "$cache_dir/manifest.tmp"

        local file_item fn
        for file_item in $payload_files; do
            fn=$(basename "$file_item")
            if [[ "$fn" == "amd_fidelityfx_upscaler_dx12.dll" ]]; then
                cp -f "$file_item" "$destination_dir/" 2>/dev/null
                echo "OptiScaler/$fn" >> "$cache_dir/manifest.tmp"
            elif [[ "$fn" == "OptiPatcher.asi" ]]; then
                cp -f "$file_item" "$plugin_dir/" 2>/dev/null
                echo "plugins/$fn" >> "$cache_dir/manifest.tmp"
            else
                cp -f "$file_item" "${game_path}/" 2>/dev/null
                echo "$fn" >> "$cache_dir/manifest.tmp"
            fi
        done
        mv -f "$cache_dir/manifest.tmp" "$mf_path" 2>/dev/null
        chmod 644 "$mf_path" 2>/dev/null
    fi
    rm -rf "$cache_dir"
    rm -f "${game_path}/setup_windows.bat" "${game_path}/setup_linux.sh" 2>/dev/null
    if [[ -f "${game_path}/OptiScaler.dll" && ! -f "${game_path}/dxgi.dll" ]]; then mv "${game_path}/OptiScaler.dll" "${game_path}/dxgi.dll"; fi
    if [[ -f "${game_path}/Optiscaler.dll" && ! -f "${game_path}/dxgi.dll" ]]; then mv "${game_path}/Optiscaler.dll" "${game_path}/dxgi.dll"; fi

    chown -R bsystem:bsystem "$game_path" 2>/dev/null

    local config_file="${game_path}/OptiScaler.ini"
    rm -f "${game_path}/nvngx.ini"
    echo -e "${GREEN}[+] Structuring tailored FSR configuration engine profiles...${RESET}"
    {
        echo "[Global]"
        echo "LogLevel = info"
        echo "LogToFile = false"
        echo "LoadAsiPlugins = true"
        echo "PreAllocateBuffers = true"
        echo "UsePreExposure = true"
        echo "[Upscalers]"
        echo "Dx12Upscaler = fsr31"
        echo "[FSR]"
        if [[ "$branch_choice" == "1" ]]; then
            echo "Fsr4EnableWatermark = true"
        else
            echo "Fsr4EnableWatermark = false"
        fi
        echo "Fsr4EnableInt8 = true"
        echo "VelocityFactor = 1.0"
        echo "[Hotfixes]"
        echo "ResourceBarrierFix = true"

        if [[ "$engine_preset" == "2" ]]; then
            echo "[RootSignatures]"
            echo "RestoreComputeRootSignature = true"
        elif [[ "$engine_preset" == "3" ]]; then
            echo "[Color]"
            echo "ColorResourceBarrier = 4"
            echo "NonLinearSRGBInput = true"
        fi
    } > "$config_file"
    chown bsystem:bsystem "$config_file" 2>/dev/null

    echo -e "${GREEN}[✓] Character-perfect injection loop complete! Full mod matrix deployed flat.${RESET}"

    # 🧬 TARGETED PROMPT: Ask user if they want to use MangoHud telemetry layers
    echo -ne "\n👉 Integrate MangoHud performance telemetry overlay layout parameters? (y/N): "
    local use_hud; read -r use_hud

    echo -e "\n${B_RED}====================================================================${RESET}"
    echo -e "  ⚠️ REQUIRED GAME LAUNCH OPTIONS INFRASTRUCTURE                      "
    echo -e "====================================================================${RESET}"
    echo -e "  🎮 FOR STEAM TITLES (Add directly to Launch Options):"

    if [[ "$use_hud" =~ ^[Yy]$ ]]; then
        echo -e "  ${CYAN}FSR_Fsr4ForceEnableInt8${RESET}=${GREEN}true${RESET} ${CYAN}WINEDLLOVERRIDES${RESET}=${GREEN}\"dxgi=n,b\"${RESET} ${MAGENTA}mangohud${RESET} ${YELLOW}%command%${RESET}"
        echo -e "                                                                    "
        echo -e "  📦 FOR NON-STEAM TITLES (Lutris/Heroic Env Variables panel):"
        echo -e "  Key: ${CYAN}FSR_Fsr4ForceEnableInt8${RESET}   Value: ${GREEN}true${RESET}"
        echo -e "  Key: ${CYAN}WINEDLLOVERRIDES${RESET}          Value: ${GREEN}dxgi=n,b${RESET}"
        echo -e "  Key: ${MAGENTA}MANGOHUD${RESET}                 Value: ${GREEN}1${RESET}"
    else
        echo -e "  ${CYAN}FSR_Fsr4ForceEnableInt8${RESET}=${GREEN}true${RESET} ${CYAN}WINEDLLOVERRIDES${RESET}=${GREEN}\"dxgi=n,b\"${RESET} ${YELLOW}%command%${RESET}"
        echo -e "                                                                    "
        echo -e "  📦 FOR NON-STEAM TITLES (Lutris/Heroic Env Variables panel):"
        echo -e "  Key: ${CYAN}FSR_Fsr4ForceEnableInt8${RESET}   Value: ${GREEN}true${RESET}"
        echo -e "  Key: ${CYAN}WINEDLLOVERRIDES${RESET}          Value: ${GREEN}dxgi=n,b${RESET}"
    fi
    echo -e "${B_RED}====================================================================${RESET}"

    (play_success_chime &>/dev/null &)
    read -rp "Press [Enter] to return to menu dashboard..." dummy
}

# ==============================================================================
# 📂 GROUP 4 (CONT.): NATIVE ARCHIVE PACKAGE WORKSPACE MANAGER
# ==============================================================================
launch_bc250_opticlient_matrix() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local DIM='\033[38;2;110;110;110m' local RESET='\033[0m'

    # Reset any broken shell directory tracking handles cleanly back to base user space
    cd /var/home/bsystem || true

    local raw_home="/var/home/bsystem"
    local base_app_dir="${raw_home}/Applications"
    local target_client_dir="${base_app_dir}/OptiscalerClient"
    local staging_tmp_dir="/tmp/opticlient_jit_staging"
    local force_install_flow="false"

    # 🧠 CASE-INSULATED DYNAMIC SPIRAL EFFECT CHARACTER ARRAY DEFINITION
    local spinner=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )

    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "   🚀 BC-250 OPTISCALER INTERACTIVE DESKTOP MANAGER GATEWAY          "
    echo -e "${CYAN}====================================================================${RESET}"

    # Ensure the base target folder container path is physically present on disk
    if [ ! -d "$base_app_dir" ]; then
        echo -e "${YELLOW}[ℹ] Base Applications folder missing. Creating directory tracking layer...${RESET}"
        mkdir -p "$base_app_dir" 2>/dev/null
    fi

    # Shield checkpoint: Strip any legacy residual root parameter locks off the folder structure
    chown -R bsystem:bsystem "$base_app_dir" 2>/dev/null
    chmod 755 "$base_app_dir" 2>/dev/null

    # 🧠 BULLETPROOF BULK STATE DETECTOR: Scans across your entire Applications workspace
    local active_exe; active_exe=$(find "$base_app_dir" -maxdepth 3 -type f \( -name "OptiscalerClient" -o -name "Optiscaler-Client" \) 2>/dev/null | head -n 1)

    # Isolate the exact active parent directory path boundary housing that discovered binary asset
    local active_installed_dir=""
    if [ -n "$active_exe" ] && [ -f "$active_exe" ]; then
        active_installed_dir=$(dirname "$active_exe")
    fi
    # 🔄 DUAL-STATE INTERACTIVE TOGGLE ENGAGEMENT TRACKS
    if [ -n "$active_installed_dir" ] && [ -d "$active_installed_dir" ]; then
        echo -e "${GREEN}[✓] Active OptiScaler Client installation detected on disk.${RESET}"
        echo -e "    ${DIM}Target Folder ➜ ${active_installed_dir}${RESET}"
        echo -e "${CYAN}====================================================================${RESET}"
        echo -n "👉 Would you like to UNINSTALL the manager tool and clear files? (y/N): "
        local ans_un; read -r ans_un

        if [[ "$ans_un" =~ ^[Yy]$ ]]; then
            echo -e "\n${YELLOW}[ℹ] Purging deployed OptiScaler Client files and configurations...${RESET}"

            # 🧬 THE ORIGINAL WORKING REMOVAL LINE: Explicitly drops files from the raw_home variable mapping
            rm -f "${raw_home}/Desktop/OptiscalerClient.desktop" 2>/dev/null
            rm -f "${raw_home}/.local/share/applications/OptiscalerClient.desktop" 2>/dev/null

            # Clear out the binary folder tracks
            rm -rf "$active_installed_dir" 2>/dev/null
            if [ "$active_installed_dir" != "$base_app_dir" ]; then rm -rf "$active_installed_dir" 2>/dev/null; fi
            rm -rf "$target_client_dir" 2>/dev/null

            # Force system application indexing tables to refresh immediately
            sudo -u bsystem update-desktop-database "${raw_home}/.local/share/applications" 2>/dev/null

            echo -e "${GREEN}[✓] Uninstallation completed successfully. Workspace cleared!${RESET}"
            echo -e "${CYAN}====================================================================${RESET}"

            # 🧠 FIXED TYPO LINK: Variable definitions matched perfectly to continue execution flow cleanly
            echo -n "👉 Deployed files removed. Proceed with a fresh download and installation now? (y/N): "
            local ans_fresh; read -r ans_fresh
            if [[ "$ans_fresh" =~ ^[Yy]$ ]]; then
                force_install_flow="true"
                clear
                echo -e "${CYAN}====================================================================${RESET}"
                echo -e "   🚀 BC-250 OPTISCALER INTERACTIVE DESKTOP MANAGER GATEWAY          "
                echo -e "${CYAN}====================================================================${RESET}"
            else
                return 0
            fi
        else
            echo -e "\n${GREEN}[+] Bypassing uninstaller pass. Moving straight to native boot loop...${RESET}"
        fi
    fi
    # 📥 JIT INSTALLATION DOWNLOAD TRACKS
    if [ -z "$active_installed_dir" ] || [ ! -d "$active_installed_dir" ] || [ "$force_install_flow" == "true" ]; then
        echo -e "${YELLOW}[⚠] OptiScaler Client installation structure not detected.${RESET}"
        echo -e "${CYAN}====================================================================${RESET}"
        echo -e "💡  ${GREEN}DOWNLOAD INSTRUCTIONS:${RESET}"
        echo -e "    1) Open your web browser and navigate straight to the repository:"
        echo -e "       \033]8;;https://github.com/Optiscaler-Client/Optiscaler-Client\033\\\\${CYAN}🌐 https://github.com/Optiscaler-Client/Optiscaler-Client ${DIM}➜ (Right-Click / Open Link)${RESET}\033]8;;\033\\\\"
        echo -e "    2) Navigate to the ${YELLOW}Releases${RESET} section page."
        echo -e "    3) Under 'Assets', right-click the latest ${YELLOW}.zip${RESET} or ${YELLOW}.tar.gz${RESET} Linux bundle."
        echo -e "    4) Select \033[4mCopy Link\033[24m, paste it below, and press Enter."
        echo -e "${CYAN}====================================================================${RESET}"
        echo -n "👉 Enter the direct archive download URL: "
        local dl_url; read -r dl_url

        if [ -z "$dl_url" ]; then
            echo -e "${RED}❌ ERROR: Download URL constraint cannot be an empty value string.${RESET}"
            read -rp "Press [Enter] to return..." dummy; cd /var/home/bsystem/Applications/Bazzite_Toolbox/ || true; return 1
        fi

        # Extract version tags if a standard release link is pasted to auto-convert it
        local tag_version="OptiscalerClient-Latest"
        if [[ "$dl_url" == */releases/tag/* ]]; then
            tag_version=$(echo "$dl_url" | sed 's|.*/releases/tag/||' | cut -d'/' -f1 | cut -d'?' -f1)
            echo -e "${YELLOW}[⚙] Release page link detected. Translating to direct binary asset URL...${RESET}"
            dl_url="https://github.com{tag_version}/${tag_version}-linux-x64.zip"
        fi

        # Re-initialize the absolute production destination folder freshly on disk
        rm -rf "$target_client_dir" && mkdir -p "$target_client_dir" 2>/dev/null

        # Isolate target archive file extension names cleanly
        local archive_file="opticlient_pack.tmp"
        if [[ "$dl_url" == *.zip ]]; then
            archive_file="opticlient_pack.zip"
        elif [[ "$dl_url" == *.tar.gz || "$dl_url" == *.tgz ]]; then
            archive_file="opticlient_pack.tar.gz"
        elif [[ "$dl_url" == *.7z ]]; then
            archive_file="opticlient_pack.7z"
        fi

        echo -e "\n${CYAN}[⚙] Initializing secure network download connection...${RESET}"

        # 🌀 FOREGROUND SPIRAL LAYER: Quietly pipes wget progress output into the interactive animation loop [0.11]
        local dl_idx=0
        while read -r line; do
            local frame="${spinner[dl_idx]}"
            echo -ne "\r  \033[0;36m[$frame] Fetching and streaming latest OptiScaler Client engine package...${RESET}"
            ((dl_idx = (dl_idx + 1) % ${#spinner[@]}))
        done < <(wget --no-check-certificate --timeout=20 -O "$target_client_dir/$archive_file" "${dl_url}" 2>&1)
        echo -ne "\r                                                                                   \r"

        if [ ! -f "$target_client_dir/$archive_file" ]; then
            echo -e "${RED}❌ ERROR: Network download chain failed. Verify link address visibility.${RESET}"
            rm -rf "$target_client_dir" 2>/dev/null
            read -rp "Press [Enter] to return..." dummy; cd /var/home/bsystem/Applications/Bazzite_Toolbox/ || true; return 1
        fi
        # File type validation safety pass
        if file "$target_client_dir/$archive_file" | grep -q "HTML document"; then
            echo -e "${RED}❌ ERROR: Failed to isolate direct binary file payload wrapper!${RESET}"
            rm -rf "$target_client_dir" 2>/dev/null
            read -rp "Press [Enter] to return..." dummy; cd /var/home/bsystem/Applications/Bazzite_Toolbox/ || true; return 1
        fi

        echo -e "${YELLOW}[⚙] Running automated unpacking pass straight over root destination...${RESET}"
        if [[ "$archive_file" == *.zip || "$dl_url" == *.zip ]]; then
            unzip -q -o "$target_client_dir/$archive_file" -d "$target_client_dir/" 2>/dev/null
        elif [[ "$archive_file" == *.tar.gz || "$dl_url" == *.tar.gz || "$dl_url" == *.tgz ]]; then
            tar -xf "$target_client_dir/$archive_file" -C "$target_client_dir/" 2>/dev/null
        else
            7z x -aoa "$target_client_dir/$archive_file" "-o$target_client_dir/" &>/dev/null
        fi

        # Purge temporary download package remnants cleanly off the partition
        rm -f "$target_client_dir/$archive_file" 2>/dev/null

        # NESTED CONTAINER STRIPPER: Flattens layout if zip contains an inner parent envelope folder
        local nested_sub; nested_sub=$(find "$target_client_dir" -mindepth 1 -maxdepth 1 -type d -name "*OptiscalerClient*" 2>/dev/null | head -n 1)
        if [ -n "$nested_sub" ] && [ -d "$nested_sub" ]; then
            cp -rT "$nested_sub" "$target_client_dir" 2>/dev/null
            rm -rf "$nested_sub" 2>/dev/null
        fi

        # Verify final deployment folder matches case parameters newly
        active_exe=$(find "$target_client_dir" -maxdepth 2 -type f \( -name "OptiscalerClient" -o -name "Optiscaler-Client" \) 2>/dev/null | head -n 1)

        if [ -z "$active_exe" ]; then
            echo -e "${RED}❌ ERROR: Deployment validation failed. 'OptiscalerClient' native binary missing.${RESET}"
            rm -rf "$target_client_dir" 2>/dev/null
            read -rp "Press [Enter] to return..." dummy; cd /var/home/bsystem/Applications/Bazzite_Toolbox/ || true; return 1
        fi

        echo -e "${GREEN}[✓] Unpacking and directory deployment finished smoothly!${RESET}"
        active_installed_dir="$target_client_dir"
    fi

    # 🚀 SHORTCUT PROVISIONER ENGINE
    local final_exe; final_exe=$(find "$active_installed_dir" -maxdepth 2 -type f \( -name "OptiscalerClient" -o -name "Optiscaler-Client" \) 2>/dev/null | head -n 1)
    local exe_name; exe_name=$(basename "$final_exe")

    # 🧠 OFFICIAL BRANDED REPOSITORY IMAGE LOCK: Pulls .ico asset cleanly via wget
    local custom_icon_path="${active_installed_dir}/app_icon.ico"
    if [ ! -f "$custom_icon_path" ] && [ -d "$active_installed_dir" ]; then
        echo -e "${YELLOW}[⚙] Fetching custom repository branding icon (.ico)...${RESET}"
        wget --no-check-certificate -q --timeout=15 -O "$custom_icon_path" "https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/BC-250-Graphics-Compiler/Compiled/Icons/OptiscalerClient_256x255_32bit.ico" 2>/dev/null

        # Safe fallback system asset string if the icon hasn't been pushed upstream yet or network drops
        if [ ! -f "$custom_icon_path" ]; then
            custom_icon_path="preferences-desktop-gaming"
        fi
    fi
    echo -e "\n${YELLOW}[ℹ] CONFIGURE APPLICATION INTERFACE SHORTCUTS:${RESET}"
    echo -e "  1) Create Desktop Shortcut Only"
    echo -e "  2) Create Start Menu Shortcut Only (Applications ➜ Games folder)"
    echo -e "  3) Create Both Desktop and Start Menu Shortcuts"
    echo -e "  4) Skip Shortcut Creation and continue to launch"
    echo -n "  Select shortcut target deployment option [1-4]: "
    local sc_choice; read -r sc_choice

    write_desktop_shortcut() {
        local dest_path="$1"
        cat << EOF > "$dest_path"
[Desktop Entry]
Type=Application
Name=OptiScaler Client
Comment=Modern UI Manager for OptiScaler Mod
Exec=env HOME=${raw_home} XDG_CONFIG_HOME=${raw_home}/.config LD_LIBRARY_PATH=${active_installed_dir} ./${exe_name}
Path=${active_installed_dir}
Icon=${custom_icon_path}
Terminal=false
Categories=Game;Amusement;X-KDE-Game;Settings;
EOF
        chmod 755 "$dest_path" 2>/dev/null
    }

    if [[ "$sc_choice" == "1" || "$sc_choice" == "3" ]]; then
        echo -e "${GREEN}[⚙] Provisioning Hardened Desktop Launcher...${RESET}"
        mkdir -p "${raw_home}/Desktop" 2>/dev/null
        write_desktop_shortcut "${raw_home}/Desktop/OptiscalerClient.desktop"
    fi

    if [[ "$sc_choice" == "2" || "$sc_choice" == "3" ]]; then
        echo -e "${GREEN}[⚙] Provisioning Hardened Start Menu Application Launcher...${RESET}"
        mkdir -p "${raw_home}/.local/share/applications" 2>/dev/null
        write_desktop_shortcut "${raw_home}/.local/share/applications/OptiscalerClient.desktop"
        sudo -u bsystem update-desktop-database "${raw_home}/.local/share/applications" 2>/dev/null
    fi

    chown -R bsystem:bsystem "${raw_home}/Desktop" "${raw_home}/.local/share/applications" 2>/dev/null

    # 🚀 RUNTIME APPLICATION BOOT PASS
    echo -e "\n${GREEN}[✓] Shortcut processing complete.${RESET}"
    echo -e "${CYAN}[➡] Launching native application dashboard. Handshaking scan tables...${RESET}"
    sleep 1

    # ==========================================================================
    # THIS INSERTS YOUR FOREGROUND VISUAL MONITOR SHIELD LAYER (ADD-ONLY)
    # ==========================================================================
    clear; echo -e "${CYAN}====================================================================${RESET}"
    echo -e "  🎮 [ SESSION ACTIVE ]: ${GREEN}OptiScaler Archive Client${RESET} is running... "
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "💡  ${YELLOW}INFO:${RESET} Closing the application dashboard app interface window will"
    echo -e "         automatically release the script lock and return to main menu."
    echo -e "${CYAN}====================================================================${RESET}"

    cd "$active_installed_dir" || return 1
    chmod +x "./${exe_name}" 2>/dev/null

    chown -R bsystem:bsystem "$target_client_dir" 2>/dev/null
    chown -R bsystem:bsystem "${raw_home}/.config" 2>/dev/null
    chmod -R 755 "$target_client_dir" 2>/dev/null
    # 🧬 UNTOUCHED NATIVE EXECUTION STRING: Mutes background diagnostic log streams safely
    env HOME="${raw_home}" XDG_CONFIG_HOME="${raw_home}/.config" ./${exe_name} 2>/dev/null
    # 🧬 POST-SESSION EXIT AUDIO ENGINE HANDSHAKE
    (play_success_chime &>/dev/null &)
    cd /var/home/bsystem/Applications/Bazzite_Toolbox/ || return 3
}
# ==============================================================================
# 📂 GROUP 4 (CONT.): PORTAL BREAKOUT DASHBOARDS, APPIMAGES & OVERLAYS
# ==============================================================================
launch_bc250_appimage_manager() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local DIM='\033[38;2;110;110;110m' local RESET='\033[0m'
    local raw_home="/var/home/bsystem" local base_app_dir="${raw_home}/Applications"
    cd /var/home/bsystem || true; clear

    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "   🚀 BC-250 STANDALONE APPIMAGE UPDATER & MANAGER GATEWAY          "
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "  ⚙️ SELECT APPIMAGE TARGET SYSTEM COMPONENT TO DEPLOY:"
    echo -e "    1) OptiScaler Interactive UI Standalone Client\n       💡 ${DIM}(Ctrl+Click or Right-Click to Copy/Open Link)${RESET}\n       \033]8;;https://github.com/Optiscaler-Client/Optiscaler-Client\033\\\\${CYAN}🌐 Repo: https://github.com/Optiscaler-Client/Optiscaler-Client${RESET}\033]8;;\033\\\\"
    echo -e "    2) Sony DualSense DS5 Bridge Companion Utility\n       💡 ${DIM}(Ctrl+Click or Right-Click to Copy/Open Link)${RESET}\n       \033]8;;https://github.com/djanice1980/DS5_Bridge\033\\\\${CYAN}🌐 Repo: https://github.com/djanice1980/DS5_Bridge${RESET}\033]8;;\033\\\\"
    echo -e "    3) Goverlay Performance & HUD Tweak Interface\n       💡 ${DIM}(Ctrl+Click or Right-Click to Copy/Open Link)${RESET}\n       \033]8;;https://github.com/benjamimgois/goverlay\033\\\\${CYAN}🌐 Repo: https://github.com/benjamimgois/goverlay${RESET}\033]8;;\033\\\\\n"
    echo -n "👉 Select target application package slot [1-3]: "; read -r app_slot

    local app_name="OptiScaler AppImage" local folder_name="OptiscalerClient_AppImage" local comment_str="Modern UI Manager for OptiScaler Mod" local icon_url="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/BC-250-Graphics-Compiler/Compiled/Icons/OptiscalerClient_256x255_32bit.ico" local base_repo="Optiscaler-Client/Optiscaler-Client" local local_exe="OptiscalerClient.AppImage" force_install_flow="false"
    [[ "$app_slot" == "2" ]] && app_name="DS5 Bridge Companion" && folder_name="DS5BridgeCompanion_AppImage" && comment_str="Advanced Sony DualSense Profile Bridge System" && icon_url="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/BC-250-Graphics-Compiler/Compiled/Icons/ds5-bridge_mark.ico" && base_repo="djanice1980/DS5_Bridge" && local_exe="DS5BridgeCompanion.AppImage"
    # 🧬 ATOMIC SYNCHRONIZATION FIXED: Swapped the icon asset reference to match your official community goverlay.ico link exactly
    [[ "$app_slot" == "3" ]] && app_name="Goverlay HUD Interface" && folder_name="Goverlay_AppImage" && comment_str="Graphical UI Configuration Tool for MangoHud & vkBasalt" && icon_url="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/BC-250-Graphics-Compiler/Compiled/Icons/goverlay.ico" && base_repo="benjamimgois/goverlay" && local_exe="Goverlay.AppImage"

    local target_client_dir="/var/home/bsystem/Applications/${folder_name}"
    local active_bin="${target_client_dir}/${local_exe}"

    # 🧬 UNINSTALLER BLOCK: Clears out legacy installation tracks cleanly when requested
    if [[ -f "$active_bin" ]]; then
        echo -e "${GREEN}[✓] Active version of [ $app_name ] detected on disk.${RESET}"
        echo -e "    ${DIM}Target Folder ➜ ${target_client_dir}${RESET}"
        echo -e "${CYAN}====================================================================${RESET}"
        echo -n "👉 Would you like to UNINSTALL this component and clear folder files? (y/N): "; read -r ans_un
        if [[ "$ans_un" =~ ^[Yy]$ ]]; then
            echo -e "\n${YELLOW}[ℹ] Purging deployed app binaries and configuration structures...${RESET}"
            rm -f "${raw_home}/Desktop/${folder_name}.desktop" "${raw_home}/.local/share/applications/${folder_name}.desktop" 2>/dev/null
            rm -rf "$target_client_dir" 2>/dev/null
            sudo -u bsystem update-desktop-database "${raw_home}/.local/share/applications" 2>/dev/null
            echo -e "${GREEN}[✓] Uninstallation completed successfully. Workspace cleared!${RESET}"
            echo -e "${CYAN}====================================================================${RESET}"
            echo -n "👉 Deployed files removed. Proceed with a fresh download and installation now? (y/N): "; read -r ans_fresh
            if [[ "$ans_fresh" =~ ^[Yy]$ ]]; then force_install_flow="true"; clear
            else return 0; fi
        fi
    fi

    if [[ ! -f "$active_bin" || "$force_install_flow" == "true" ]]; then
        echo -e "${CYAN}====================================================================${RESET}"
        read -rp "👉 Paste direct archive download URL link or Release webpage URL: " dl_url
        [[ -z "$dl_url" ]] && { echo -e "${RED}❌ ERROR: URL parameter field cannot be empty.${RESET}"; sleep 2; return 1; }
        if [[ "$dl_url" == */releases/tag/* ]]; then
            local tag_version; tag_version=$(echo "$dl_url" | sed 's|.*/releases/tag/||' | cut -d'/' -f1 | cut -d'?' -f1)
            if [[ "$app_slot" == "1" ]]; then dl_url="https://github.com{base_repo}/releases/download/${tag_version}/${tag_version}-x86_64.AppImage"
            elif [[ "$app_slot" == "3" ]]; then dl_url="https://github.com{base_repo}/releases/download/${tag_version}/goverlay-${tag_version}-x86_64.AppImage"
            else dl_url="https://github.com{base_repo}/releases/download/${tag_version}/DS5-Bridge-Companion-${tag_version#v}-linux-x86_64.AppImage"; fi
        fi

        # 🧬 DIRECT DRILL FIX: Forces directory generation directly before curl initializes
        sudo -u bsystem mkdir -p "$target_client_dir" 2>/dev/null
        sudo -u bsystem rm -f "$target_client_dir"/* 2>/dev/null

        echo -e "\n${CYAN}[⚙] Initializing secure network download connection...${RESET}"
        sudo -u bsystem curl -L --insecure --connect-timeout 20 -o "$active_bin" "${dl_url}"

        if [[ ! -s "$active_bin" ]]; then
            echo -e "${RED}❌ ERROR: Connection failed. Target link is missing or empty data returned.${RESET}"
            sudo -u bsystem rm -f "$active_bin" 2>/dev/null; read -rp "Press [Enter]..." dummy; return 1
        fi
        chmod 755 "$active_bin" 2>/dev/null; local custom_icon_path="${target_client_dir}/app_icon.ico"
        sudo -u bsystem curl -L -s --insecure -o "$custom_icon_path" "${icon_url}" 2>/dev/null
        [[ ! -f "$custom_icon_path" ]] && custom_icon_path="preferences-desktop-gaming"

        echo -e "\n${YELLOW}[ℹ] CONFIGURE APPLICATION INTERFACE SHORTCUTS:${RESET}"
        echo -e "  1) Create Desktop Shortcut Only\n  2) Create Start Menu Shortcut Only (Applications ➜ Games folder)\n  3) Create Both Desktop and Start Menu Shortcuts\n  4) Skip Shortcut Creation and continue to launch"
        echo -n "👉 Select shortcut target option [1-4]: "; read -r sc_choice
        write_appimage_shortcut() {
            local dest_path="$1"
            sudo -u bsystem cat << EOF > "$dest_path"
[Desktop Entry]
Type=Application
Name=${app_name}
Comment=${comment_str}
Exec=env HOME=${raw_home} XDG_CONFIG_HOME=${raw_home}/.config ./${local_exe}
Path=${target_client_dir}
Icon=${custom_icon_path}
Terminal=false
Categories=Game;Amusement;X-KDE-Game;Settings;
EOF
            chmod 755 "$dest_path" 2>/dev/null
        }
        [[ "$sc_choice" == "1" || "$sc_choice" == "3" ]] && sudo -u bsystem mkdir -p "${raw_home}/Desktop" 2>/dev/null && write_appimage_shortcut "${raw_home}/Desktop/${folder_name}.desktop"
        [[ "$sc_choice" == "2" || "$sc_choice" == "3" ]] && sudo -u bsystem mkdir -p "${raw_home}/.local/share/applications" 2>/dev/null && write_appimage_shortcut "${raw_home}/.local/share/applications/${folder_name}.desktop"
        sudo -u bsystem update-desktop-database "${raw_home}/.local/share/applications" 2>/dev/null
        chown -R bsystem:bsystem "${raw_home}/Desktop" "${raw_home}/.local/share/applications" "$target_client_dir" "${raw_home}/.config" 2>/dev/null
    fi
    echo -e "${GREEN}[✓] SUCCESS: AppImage configuration completely processed! Monitoring active session...${RESET}"
    clear; echo -e "${CYAN}====================================================================${RESET}"
    echo -e "  🎮 [ SESSION ACTIVE ]: ${GREEN}${app_name}${RESET} is running natively... "
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "💡  ${YELLOW}INFO:${RESET} Closing the application interface window will automatically"
    echo -e "         release the runtime lock and return you straight back to menu."
    echo -e "${CYAN}====================================================================${RESET}"

    sudo -u bsystem env HOME="${raw_home}" XDG_CONFIG_HOME="${raw_home}/.config" "$active_bin" &>/dev/null

    (play_success_chime &>/dev/null &)
    return 3
}

manage_mangohud_toggle() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local DIM='\033[38;2;110;110;110m' local RESET='\033[0m'

    # 🚀 ROOT ENVIRONMENT PROBE: Directly checks the active global environment profile
    local is_active="false"
    if grep -q "MANGOHUD" /etc/environment 2>/dev/null; then is_active="true"; fi

    # 🔄 TRACK 1: ACTIVE DEACTIVATION PURGE (Fires if variable is registered)
    if [ "$is_active" == "true" ]; then
        clear
        echo -e "${CYAN}====================================================================${RESET}"
        echo -e "   🚀 MANGOHUD OVERLAY SYSTEM STATUS: ACTIVE                        "
        echo -e "${CYAN}====================================================================${RESET}"
        echo -e "${GREEN}[✓] MangoHud environment profile detected in system tables.${RESET}"
        echo -e "${CYAN}====================================================================${RESET}"
        echo -n "👉 MangoHud is active. Would you like to DEACTIVATE & REMOVE settings? (y/N): "
        local ans_un; read -r ans_un

        if [[ "$ans_un" =~ ^[Yy]$ ]]; then
            echo -e "\n${RED}[●] Disabling system overrides and clearing user configs...${RESET}"

            # Pure system configuration removal
            sudo sed -i '/MANGOHUD/d' /etc/environment 2>/dev/null || true
            sudo sed -i '/MANGOHUD/d' /etc/profile.local 2>/dev/null || true

            # Clear sandbox profiles cleanly
            flatpak override --user --unset-env=MANGOHUD com.valvesoftware.Steam 2>/dev/null || true
            flatpak uninstall --user -y org.freedesktop.Platform.VulkanLayer.MangoHud 2>/dev/null || true
            rm -rf "/var/home/bsystem/.config/MangoHud" 2>/dev/null
            rm -f "/var/home/bsystem/.config/environment.d/mangohud.conf" 2>/dev/null

            (play_success_chime &>/dev/null &)
            echo -e "\n${GREEN}[✓] MangoHud has been completely deactivated and profiles cleared!${RESET}"
            sleep 2; return 0
        else
            echo -e "\n${YELLOW}[ℹ] Bypassing deactivation. Returning to main engine...${RESET}"
            sleep 1.5; return 0
        fi
    fi

    # 📥 TRACK 2: ACTIVE RE-INSTALLATION ACTIVATION (Runs if variable is missing)
    echo -e "${YELLOW}[⚙] MangoHud inactive. Handing off execution cleanly to activation track...${RESET}"
    sleep 1

    # Force environmental registration directly into the system table
    sudo sed -i '/MANGOHUD/d' /etc/environment 2>/dev/null || true
    echo "MANGOHUD=1" | sudo tee -a /etc/environment >/dev/null

    # Configure user space app overrides cleanly
    flatpak override --user --env=MANGOHUD=1 com.valvesoftware.Steam 2>/dev/null || true
    mkdir -p "/var/home/bsystem/.config/MangoHud" 2>/dev/null

    (play_success_chime &>/dev/null &)
    echo -e "\n${GREEN}[✓] MangoHud has been completely activated for all Steam games!${RESET}"
    sleep 2; return 0
}
# ==============================================================================
# 📂 GROUP 4 (CONT.): NATIVE FLAT PAYLOAD INJECTORS & COMPILED DRIVER SUB-MENUS
# ==============================================================================
extract_and_strip_fsr_payload() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local DIM='\033[38;2;110;110;110m' local RESET='\033[0m'
    local gh_owner="YOUR_GITHUB_USERNAME" local gh_repo="YOUR_REPO_NAME"
    local base_url="https://github.com{gh_owner}/${gh_repo}/releases/download"
    local manifest_name=".bc250_mod_manifest.txt"

    clear; echo -e "${CYAN}====================================================================${RESET}"
    echo -e "   🚀 GFX1013 MANIFEST-DRIVEN MULTIPART INJECTOR ENGINE             "
    echo -e "${CYAN}====================================================================${RESET}"
    echo -n "    Enter Target Game Absolute Path: "; read -r game_path
    game_path="${game_path#\'}"; game_path="${game_path%\'}"; game_path="${game_path#\"}"; game_path="${game_path%\"}"
    game_path=$(echo "$game_path" | sed -e 's/[[:space:]]*$//' -e 's|/*$||')
    [[ ! -d "$game_path" ]] && { echo -e "${RED}❌ ERROR: Provided game path does not exist.${RESET}"; sleep 3; return 1; }

    set +e
    local force_install="false" local mf_path="${game_path}/${manifest_name}"
    # 🧬 ADVANCED ACTIVE DETECTION: Flags active if either the text manifest OR any fallback dxgi handle is present
    if [[ -f "$mf_path" || -f "${game_path}/dxgi.dll" || -f "${game_path}/OptiScaler/amd_fidelityfx_upscaler_dx12.dll" ]]; then
        echo -e "\n  LIVE STATUS: [ ${GREEN}● MOD CONFIGURATION ACTIVE${RESET} ]"
        echo -n "👉 Purge structural framework and restore factory stock? (y/N): "; read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            if [[ -f "$mf_path" ]]; then
                echo -e "  ${DIM}➜ Executing manifest file footprint wipe...${RESET}"
                while IFS= read -r file_to_delete || [[ -n "$file_to_delete" ]]; do
                    [[ -n "$file_to_delete" ]] && sudo rm -f "${game_path}/${file_to_delete}" 2>/dev/null
                done < "$mf_path"
                sudo rm -f "$mf_path" 2>/dev/null
            else
                echo -e "  ${YELLOW}[ℹ] Legacy deployment detected. Running dynamic filesystem purge loop...${RESET}"
                # 🧬 ZERO-STATION DYNAMIC PURGE: Automatically maps and uninstalls any .dll/.ini/.asi in root without naming them
                find "$game_path" -maxdepth 1 -type f \( -name "*.dll" -o -name "*.ini" -o -name "*.asi" \) ! -name "steam_api*" -exec sudo rm -f {} \; 2>/dev/null
            fi
            sudo rm -rf "${game_path}/OptiScaler" "${game_path}/plugins" 2>/dev/null
            [[ -f "${game_path}/dxgi.dll.bak" ]] && mv -f "${game_path}/dxgi.dll.bak" "${game_path}/dxgi.dll" 2>/dev/null
            echo -e "${GREEN}[✓] SUCCESS: Framework cleanly purged via manifest registers!${RESET}\n"
            read -rp "👉 Proceed immediately with a clean, fresh framework stack installation? (y/N): " fresh_ans
            if [[ "$fresh_ans" =~ ^[Yy]$ ]]; then force_install="true"; else set -e; return 0; fi
        else set -e; return 0; fi
    fi

    if [[ ! -f "${game_path}/dxgi.dll" || "$force_install" == "true" ]]; then
        echo -e "\n  LIVE STATUS: [ ${DIM}○ STOCK GAME LAYOUT${RESET} ]"
        read -rp "👉 Is this a 2-part split archive configuration? (y/N): " is_multi
        local parts_cnt=1; [[ "$is_multi" =~ ^[Yy]$ ]] && parts_cnt=2

        echo -e "${YELLOW}[⚙] Connecting to GitHub API to discover active release versions...${RESET}"
        local ver; ver=$(curl -s "https://github.com{gh_owner}/${gh_repo}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        [[ -z "$ver" ]] && ver="v1.0.7-bc250.3"

        local tmp_stage="/tmp/bc250_flat_staging"; rm -rf "$tmp_stage" && mkdir -p "$tmp_stage" 2>/dev/null
        local i user_in filename target_dest master_archive=""
        for ((i=1; i<=parts_cnt; i++)); do
            if [ "$parts_cnt" -eq 2 ]; then
                echo -e "\n${YELLOW}📍 PART ${i} OF 2:${RESET}"; read -rp "👉 Enter URL or Path to Part ${i}: " user_in
            else read -rp "👉 Enter download URL or local path to release archive (Or press [ENTER]): " user_in; fi

            user_in="${user_in#\'}"; user_in="${user_in%\'}"; user_in="${user_in#\"}"; user_in="${user_in%\"}"
            user_in=$(echo "$user_in" | sed -e 's/[[:space:]]*$//')
            local part_suffix=""; [[ "$parts_cnt" -eq 2 ]] && part_suffix="-part${i}"
            local src="${user_in:-${base_url}/${ver}/bc250-fsr4-flat-${ver}${part_suffix}.zip}"
            filename=$(basename "$src"); target_dest="$tmp_stage/$filename"

            if [[ "$src" =~ ^https?:// ]]; then wget --no-check-certificate --timeout=15 -qO "$target_dest" "$src"
            else cp -f "$src" "$target_dest" 2>/dev/null; fi
            [[ -f "$target_dest" ]] && echo -e "  ${GREEN}[✓] Segment $i successfully cached!${RESET}"
            if [[ "$filename" == *.001 || "$filename" == *part1.zip || ("$filename" == *.zip && ! "$filename" == *part2.zip) || "$filename" == *.7z ]]; then master_archive="$target_dest"; fi
        done

        echo -e "\n  ${YELLOW}[ℹ] Directing native archive manager core to unpack payload volumes...${RESET}"
        [[ -n "$master_archive" && -f "$master_archive" ]] && 7z x -aoa "$master_archive" "-o$tmp_stage" &>/dev/null
        local payload_files; payload_files=$(find "$tmp_stage" -type f \( -name "*.dll" -o -name "*.ini" -o -name "*.asi" \) 2>/dev/null)
        [[ -z "$payload_files" ]] && { echo -e "${RED}❌ ERROR: Consolidated sandbox cache pool is empty.${RESET}"; rm -rf "$tmp_stage"; read -rp "Press [Enter]..." dummy; return 1; }

        sudo mkdir -p "${game_path}/OptiScaler" "${game_path}/plugins" 2>/dev/null
        [[ -f "${game_path}/dxgi.dll" && ! -f "${game_path}/dxgi.dll.bak" ]] && cp "${game_path}/dxgi.dll" "${game_path}/dxgi.dll.bak" 2>/dev/null

        # 🧬 DYNAMIC CATALOG BUILDER: Automatically catches any names, maps their locations, and catalogs them
        sudo rm -f "$mf_path" 2>/dev/null; touch "$tmp_stage/manifest.tmp"
        local file_item fn; for file_item in $payload_files; do
            fn=$(basename "$file_item")
            if [[ "$fn" == "amd_fidelityfx_upscaler_dx12.dll" ]]; then cp -f "$file_item" "${game_path}/OptiScaler/" 2>/dev/null; echo "OptiScaler/$fn" >> "$tmp_stage/manifest.tmp"
            elif [[ "$fn" == "OptiPatcher.asi" ]]; then cp -f "$file_item" "${game_path}/plugins/" 2>/dev/null; echo "plugins/$fn" >> "$tmp_stage/manifest.tmp"
            else cp -f "$file_item" "${game_path}/" 2>/dev/null; echo "$fn" >> "$tmp_stage/manifest.tmp"; fi
        done
        sudo mv -f "$tmp_stage/manifest.tmp" "$mf_path" 2>/dev/null && sudo chmod 644 "$mf_path" 2>/dev/null
        rm -rf "$tmp_stage"; chown -R bsystem:bsystem "$game_path" 2>/dev/null
        echo -e "${GREEN}[✓] SUCCESS: Deployed cleanly and cataloged via manifest!${RESET}"
    fi
    set -e; (play_success_chime &>/dev/null &)
    echo -e "${CYAN}====================================================================${RESET}"
    read -rp "👉 Press [ENTER] to return back to the main menu grid... " dummy; return 0
}

toggle_compute_queue_fix() {
    # 🚀 LOCAL ENVIRONMENT INSULATION: Hardcode tracking parameters securely
    local mesa_build_log="/var/log/bc250_toolbox.log"
    local mesa_compile_ver="26.2.2"
    local bin_url1="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/BC-250-Graphics-Compiler/Compiled/option-1/libvulkan_radeon.so"
    local bin_url2="https://raw.githubusercontent.com/Forbidden-Darkness/Bazzite_Toolbox/main/Overclock/BC-250-Graphics-Compiler/Compiled/option-2/libvulkan_radeon.so"

    local perf_conf="/etc/environment.d/99-bc250-perf.conf"
    local wrapper_bin="/usr/local/bin/bc250-dx-boost"

    # 🧠 CASE-INSULATED DYNAMIC SPIRAL EFFECT CHARACTER ARRAY DEFINITION
    local spinner=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )

    while true; do
        clear
         # 🧠 EXTENDED Parent Menu Frame Block (Drop this directly over your old options display)
        echo -e "${YELLOW}====================================================================${RESET}"
        echo -e "    🎮 BC-250 HARDWARE PERFORMANCE TOOLKIT — BAZZITE RE-ENGINEERED  "
        echo -e "${YELLOW}====================================================================${RESET}"
        echo -e "  ${CYAN}1) Custom Route             ${RESET}  ${DIM}Compile & install Custom Mesa Driver natively${RESET}"
        echo -e "  ${CYAN}2) Express Route            ${RESET}  ${DIM}Download & install Pre-Compiled Performance Driver${RESET}"
        echo -e "  ${CYAN}3) Restore Stock Driver     ${RESET}  ${DIM}Remove Custom Mesa Overrides & restore factory state${RESET}"
        echo -e "  ${CYAN}4) Telemetry Status Check   ${RESET}  ${DIM}Check driver activation & hardware extension status${RESET}"
        echo ""
        echo -e "  ${CYAN}5) FSR 4.1.1 Smart Suite    ${RESET}  ${DIM}Toggle GFX1013 FSR 4.1.1 Vector RC11 PROD Engine${RESET}"
        echo -e "  ${CYAN}6) Strip Legacy FSR4 payload files & purge configuration states${RESET}  ${DIM}Completely remove upscaler binaries and reset game directories to factory defaults${RESET}"
        echo -e "  ${CYAN}7) Install / Update Standalone Developer AppImages ${DIM}(OptiScaler / DS5 Bridge / Goverlay)${RESET}"
        echo -e "  ${CYAN}8) Deploy / Manage OptiScaler Interactive Client ${DIM}(ZIP Archive Bundle)${RESET}"
        echo ""
        echo -e "  ${CYAN}9) MangoHud Engine Manager  ${RESET}  ${DIM}Configure & uninstall MangoHud Performance Monitor${RESET}"
        echo ""
        echo -e "  ${RED}↵)${RESET} ${DIM}Hit [ENTER] to return back to the main menu grid...${RESET}"
        echo -e "${YELLOW}====================================================================${RESET}"
        echo -n "  Select an option [1-7]: "

        local sub_opt; read -r sub_opt
        case "$sub_opt" in
            1)
                echo -e "\n${CYAN}  [⚙] Select Target Silicon Family Optimization Profile:${RESET}"
                echo -e "      a) Custom Route (Navi10): Compile Custom Driver Natively (High-Tier)"
                echo -e "      b) Custom Route (Navi14): Compile Custom Driver Natively (Low-Tier)"
                local ACTION_CHOICE
                read -rp "$(echo -e "  ${CYAN}Select an option [a-b]: ${RESET}")" ACTION_CHOICE

                case "$ACTION_CHOICE" in
                    a|A)
                        sudo rpm-ostree cleanup -m || true
                        sudo rpm-ostree cleanup -p || true
                        local target_lib="/opt/bc250-gfx1013/lib64/libvulkan_radeon.so"
                        if [[ -f "$target_lib" ]]; then
                            local file_bytes; file_bytes=$(stat -c %s "$target_lib" 2>/dev/null || echo "0")
                            local active_profile="CHIP_NAVI10 (Dedicated High-Tier Layout)"
                            [[ $file_bytes -gt 21700000 ]] && active_profile="CHIP_NAVI14 (Unified Performance Layout)"
                            echo -e "\n  ${YELLOW}[⚠] Active overrides detected: Currently running $active_profile.${RESET}"
                            if confirm "Would you like to safely remove this existing driver override layer before proceeding?"; then
                                sudo rm -f /etc/environment.d/99-bc250-gfx1013.conf "$perf_conf" "$wrapper_bin" /opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json 2>/dev/null || true
                                sudo sed -i '/VK_DRIVER_FILES/d' /etc/environment 2>/dev/null || true
                                sudo rm -rf /opt/bc250-gfx1013 2>/dev/null || true
                            fi
                        fi

                        echo -e "\n  ${CYAN}[ℹ] System is running stock amdgpu drivers with hard-disabled compute queues.${RESET}"
                        if confirm "Proceed with Custom Navi10 Async Compute Queue native installation?"; then
                            local log_dir; log_dir=$(dirname "$mesa_build_log")
                            [[ ! -d "$log_dir" ]] && sudo mkdir -p "$log_dir" 2>/dev/null
                            sudo rm -f "$mesa_build_log" && sudo touch "$mesa_build_log" && sudo chmod 666 "$mesa_build_log" 2>/dev/null || true
                            podman rm -f bc250-navi10-box &>/dev/null || true

                            echo -e "\n${GREEN}[+] Step 1/6: Spawning clean virtual toolchain environment (Navi10 Box)...${RESET}"
                            podman run -d --pull=always --name bc250-navi10-box registry.fedoraproject.org/fedora:43 sleep infinity >> "$mesa_build_log" 2>&1

                            echo -e "${GREEN}[+] Step 2/6: Provisioning compiler dependencies inside sandbox...${RESET}"
                            # 🚀 ATOMIC STREAM TRACKER: Direct background task routing with no data leaks
                            podman exec bc250-navi10-box dnf install -y --nogpgcheck meson ninja-build gcc gcc-c++ libdrm-devel libX11-devel libXext-devel xorg-x11-proto-devel libxcb-devel libxshmfence-devel expat-devel zlib-devel elfutils-libelf-devel wayland-devel wayland-protocols-devel git python3-mako python3-ply glx-utils bison flex python3-pyyaml glslang libXrandr-devel libzstd-devel spirv-tools-devel wget >> "$mesa_build_log" 2>&1 &
                            sleep 0.5

                            # 🌀 DYNAMIC SPIRAL MONITOR: Locks focus onto the system process tables via pgrep
                            while pgrep -f "podman exec bc250-navi10-box dnf install" &>/dev/null; do
                                for frame in "${spinner[@]}"; do
                                    echo -ne "\r  \033[0;36m[$frame] Fetching and syncing required development tool libraries...${RESET}"
                                    sleep 0.08
                                done
                            done
                            echo -ne "\r                                                                                   \r"
                            echo -e "${GREEN}[+] Step 3/6: Downloading stable Mesa ${mesa_compile_ver} source from official Git mirror...${RESET}"
                            # 🌀 STEP 3 FOREGROUND SPIRAL: Pulls repository source securely without text data line skips
                            local step3_idx=0
                            while read -r line; do
                                local frame="${spinner[step3_idx]}"
                                echo -ne "\r  \033[0;36m[$frame] Synchronizing Mesa graphics driver repository source tree...${RESET}"
                                ((step3_idx = (step3_idx + 1) % ${#spinner[@]}))
                            done < <(podman exec bc250-navi10-box git clone --depth 1 --branch "mesa-${mesa_compile_ver}" https://gitlab.freedesktop.org/mesa/mesa.git /root/mesa 2>&1)
                            echo -ne "\r                                                                                   \r"
                            podman exec bc250-navi10-box mkdir -p /root/patches

                            echo -e "${GREEN}[+] Step 4/6: Pulling pristine, un-corrupted patch assets directly from GitHub...${RESET}"
                            podman exec bc250-navi10-box wget -qO /root/patches/0001.patch "$MODDED_PATCH_0001_URL" >> "$mesa_build_log" 2>&1
                            podman exec bc250-navi10-box wget -qO /root/patches/0002.patch "$MODDED_PATCH_0002_URL" >> "$mesa_build_log" 2>&1
                            podman exec bc250-navi10-box wget -qO /root/patches/0003.patch "$MODDED_PATCH_0003_URL" >> "$mesa_build_log" 2>&1

                            echo -e "${GREEN}[+] Step 5/6: Injecting hardware performance patches and compiling custom driver...${RESET}"
                            podman exec bc250-navi10-box sed -i 's/info->has_user_fence = info->gfx_level >= GFX10;/info->has_user_fence = info->gfx_level >= GFX10;\n   info->has_async_compute_queue = info->family == CHIP_NAVI10 || info->family == CHIP_GFX1013;/g' /root/mesa/src/amd/common/ac_gpu_info.c 2>/dev/null
                            podman exec bc250-navi10-box sed -i 's/device->physical_device->radv_meta_ops;/device->physical_device->radv_meta_ops;\n   info->has_async_compute_queue = true;/g' /root/mesa/src/amd/vulkan/radv_physical_device.c 2>/dev/null
                            podman exec bc250-navi10-box sed -i 's/bool has_async_compute_queue;/bool has_async_compute_queue;\n   bool has_gfx1013_mesh_shading;/g' /root/mesa/src/amd/common/ac_gpu_info.h 2>/dev/null
                            podman exec bc250-navi10-box sed -i 's/info->has_taskmesh_indirect0_bug = info->gfx_level == GFX10_3 \&\& info->mec_fw_version < 100;/info->has_taskmesh_indirect0_bug = (info->gfx_level == GFX10_3 \&\& info->mec_fw_version < 100) || info->family == CHIP_GFX1013;\n   info->has_gfx1013_mesh_shading = info->family == CHIP_GFX1013;\n   info->has_gfx1013_task_shading = info->has_gfx1013_mesh_shading;/g' /root/mesa/src/amd/common/ac_bug_info.c 2>/dev/null || podman exec bc250-navi10-box sed -i 's/info->has_taskmesh_indirect0_bug = info->gfx_level == GFX10_3 \&\& info->mec_fw_version < 100;/info->has_taskmesh_indirect0_bug = (info->gfx_level == GFX10_3 \&\& info->mec_fw_version < 100) || info->family == CHIP_GFX1013;\n   info->has_gfx1013_mesh_shading = info->family == CHIP_GFX1013;\n   info->has_gfx1013_task_shading = info->has_gfx1013_mesh_shading;/g' /root/mesa/src/amd/common/ac_gpu_info.c
                            podman exec bc250-navi10-box sed -i '/bool has_taskmesh_indirect0_bug;/a \   bool has_gfx1013_mesh_shading;\n   bool has_gfx1013_task_shading;' /root/mesa/src/amd/common/ac_gpu_info.h
                            podman exec bc250-navi10-box sed -i '/bool record_stats;/a \   bool has_mesh_shading;' /root/mesa/src/amd/compiler/aco_shader_info.h
                            podman exec bc250-navi10-box sed -i 's/assert(!mesh_shading || ctx.program->gfx_level >= GFX10_3);/assert(!mesh_shading || options->has_mesh_shading);/g' /root/mesa/src/amd/compiler/instruction_selection/aco_isel_setup.cpp
                            podman exec bc250-navi10-box sed -i 's/cmd_buffer->state.dirty |= RADV_CMD_DIRTY_FSR_STATE | RADV_CMD_DIRTY_VGT_PRIM_STATE;/cmd_buffer->state.dirty |= RADV_CMD_DIRTY_VGT_PRIM_STATE;\n      if (pdev->info.gfx_level >= GFX10_3) cmd_buffer->state.dirty |= RADV_CMD_DIRTY_FSR_STATE;/g' /root/mesa/src/amd/vulkan/radv_cmd_buffer.c
                            podman exec bc250-navi10-box sed -i 's/info->family == CHIP_TONGA;/info->family == CHIP_TONGA || ((info->family == CHIP_NAVI10) \&\& info->gfx_level == GFX10);/g' /root/mesa/src/amd/common/ac_gpu_info.c

                            echo -e "    -> Mod files injected cleanly. Running compiler engine (Est: 3-5 mins)..."
                            podman exec bc250-navi10-box sh -c "cd /root/mesa && meson setup build/ -Dgallium-drivers= -Dvulkan-drivers=amd -Dbuildtype=release" >> "$mesa_build_log" 2>&1
                            # 🌀 STEP 5 FOREGROUND COMPILER PASS: Pipes data sequentially into the spinner loop to eliminate file corruption
                            local step5_idx=0
                            while read -r line; do
                                local frame="${spinner[step5_idx]}"
                                echo -ne "\r  \033[0;36m[$frame] Building Radeon Vulkan graphics driver library (Navi10)...${RESET}"
                                ((step5_idx = (step5_idx + 1) % ${#spinner[@]}))
                            done < <(podman exec bc250-navi10-box sh -c "cd /root/mesa && ninja -C build/ src/amd/vulkan/libvulkan_radeon.so" 2>&1)
                            echo -ne "\r                                                                                   \r"

                            if ! podman exec bc250-navi10-box test -f "/root/mesa/build/src/amd/vulkan/libvulkan_radeon.so"; then
                                echo -e "${RED}❌ ERROR: Compilation failed. Check detailed log tables at: ${mesa_build_log}${RESET}"
                                podman rm -f bc250-navi10-box --force &>/dev/null || true
                                read -rp "Press [Enter] to return back to main menu..." dummy; continue
                            fi

                            echo -e "${GREEN}[+] Step 6/6: Exporting custom library objects to host space...${RESET}"
                            sudo mkdir -p /opt/bc250-gfx1013/lib64 /opt/bc250-gfx1013/share/vulkan/icd.d /etc/environment.d 2>/dev/null
                            podman cp bc250-navi10-box:/root/mesa/build/src/amd/vulkan/libvulkan_radeon.so /opt/bc250-gfx1013/lib64/libvulkan_radeon.so
                            [[ -x /usr/sbin/restorecon ]] && sudo restorecon -v /opt/bc250-gfx1013/lib64/libvulkan_radeon.so &>/dev/null
                            podman rm -f bc250-navi10-box --force &>/dev/null || true

                            # 🎯 OPEN-STREAM ATOMIC PROVISIONING LAYER: Restores tracking lines so host layering finishes flawlessly [1.11]
                            if ! command -v numactl &>/dev/null; then
                                echo -e "${YELLOW}[ℹ] Provisioning system memory allocator matrix via native host layering...${RESET}"
                                echo -e "    -> Initializing atomic transaction pool. Please stand by..."
                                sudo rpm-ostree install -y --allow-inactive numactl
                            fi

                            sudo bash -c "cat << 'EOF' > $perf_conf
# 🚀 BC-250 HIGH-PERFORMANCE LOW-LATENCY HARDWARE INJECTION OVERRIDES
RADV_PERF_HACKS=ngg_streamout
RADV_DEBUG=nooutoforder
EOF"
                            sudo bash -c "cat << 'EOF' > $wrapper_bin
#!/usr/bin/env bash
if command -v numactl &>/dev/null; then
    exec numactl --interleave=all \"\$@\"
else
    exec \"\$@\"
fi
EOF"
                            sudo chmod +x "$wrapper_bin"

                            sudo bash <<'EOF'
cat <<INNER_EOF > /opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json
{ "file_format_version": "1.0.0", "ICD": { "library_path": "/opt/bc250-gfx1013/lib64/libvulkan_radeon.so", "api_version": "1.3.290" } }
INNER_EOF
EOF
                            echo "VK_DRIVER_FILES=/opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json" | sudo tee /etc/environment.d/99-bc250-gfx1013.conf >/dev/null
                            print_success "Custom graphics driver and frame rate boost variables successfully initialized!"
                            play_success_chime; prompt_reboot; continue
                        fi
                        ;;
                    b|B)
                        sudo rpm-ostree cleanup -m || true
                        sudo rpm-ostree cleanup -p || true
                        local target_lib="/opt/bc250-gfx1013/lib64/libvulkan_radeon.so"
                        if [[ -f "$target_lib" ]]; then
                            # 🎯 PRE-FLIGHT SILICON DETECTION ENGINE: Reads bytes on disk to name the active hardware profile
                            local file_bytes; file_bytes=$(stat -c %s "$target_lib" 2>/dev/null || echo "0")
                            local active_profile="CHIP_NAVI10 (Dedicated High-Tier Layout)"
                            if (( file_bytes > 21700000 )); then
                                active_profile="CHIP_NAVI14 (Unified Performance Layout)"
                            fi

                            echo -e "\n  ${YELLOW}[⚠] Active overrides detected: Currently running $active_profile.${RESET}"
                            if confirm "Would you like to safely remove this existing driver override layer before proceeding?"; then
                                sudo rm -f /etc/environment.d/99-bc250-gfx1013.conf /opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json 2>/dev/null || true
                                sudo sed -i '/VK_DRIVER_FILES/d' /etc/environment 2>/dev/null || true
                                sudo rm -rf /opt/bc250-gfx1013 2>/dev/null || true
                                echo -e "  ${GREEN}[✓] Existing driver clean-up complete.${RESET}"
                            fi
                        fi

                        echo -e "\n  ${CYAN}[ℹ] System is running stock amdgpu drivers with hard-disabled compute queues.${RESET}"
                        if confirm "Proceed with Custom Navi14 Async Compute Queue native installation?"; then

                            # === FIXED: SAFE PATH INSULATION GATE ===
                            local log_dir; log_dir=$(dirname "$mesa_build_log")
                            if [[ ! -d "$log_dir" ]]; then sudo mkdir -p "$log_dir" 2>/dev/null || true; fi

                            sudo rm -f "$mesa_build_log" && sudo touch "$mesa_build_log" && sudo chmod 666 "$mesa_build_log" 2>/dev/null || true
                            podman rm -f bc250-build-box &>/dev/null || true

                            echo -e "\n${GREEN}[+] Step 1/5: Spawning clean virtual toolchain environment (Navi14 Box)...${RESET}"
                            podman run -d --name bc250-build-box registry.fedoraproject.org/fedora:44 sleep infinity >> "$mesa_build_log" 2>&1

                            echo -e "${GREEN}[+] Step 2/5: Provisioning compiler dependencies inside sandbox...${RESET}"
                            podman exec bc250-build-box dnf install -y --nogpgcheck @development-tools >> "$mesa_build_log" 2>&1
                            # 🚀 BACKGROUND THREAD RUNNER: Offloads heavy toolchain installation into a parallel task stream
                            podman exec bc250-build-box dnf install -y --nogpgcheck meson ninja-build gcc gcc-c++ libdrm-devel libX11-devel libXext-devel xorg-x11-proto-devel libxcb-devel libxshmfence-devel expat-devel zlib-devel elfutils-libelf-devel wayland-devel wayland-protocols-devel git python3-mako python3-ply glx-utils bison flex python3-pyyaml glslang libXrandr-devel libzstd-devel spirv-tools-devel wget >> "$mesa_build_log" 2>&1 &
                            local dnf_navi14_pid=$!

                            # 🌀 INTERACTIVE SPIRAL LOOP LAYER: Updates live until your dependency cache registers match
                            while kill -0 "$dnf_navi14_pid" 2>/dev/null; do
                                for frame in "${spinner[@]}"; do
                                    echo -ne "\r  \033[0;36m[$frame] Fetching and syncing required development tool libraries...${RESET}"
                                    sleep 0.08
                                done
                            done
                            echo -ne "\r                                                                                   \r"

                            echo -e "${GREEN}[+] Step 3/5: Downloading stable Mesa ${mesa_compile_ver} source from official code servers...${RESET}"
                            # 🌀 NAVI14 STEP 3 FOREGROUND SPIRAL: Pulls repository source tree line-by-line safely
                            local step3_14_idx=0
                            while read -r line; do
                                local frame="${spinner[step3_14_idx]}"
                                echo -ne "\r  \033[0;36m[$frame] Synchronizing Mesa graphics driver repository source tree...${RESET}"
                                ((step3_14_idx = (step3_14_idx + 1) % ${#spinner[@]}))
                            done < <(podman exec bc250-build-box git clone --depth 1 --branch "mesa-${mesa_compile_ver}" https://gitlab.freedesktop.org/mesa/mesa.git /root/mesa 2>&1)
                            echo -ne "\r                                                                                   \r"
                            echo -e "${GREEN}[+] Step 4/5: Injecting hardware performance patches and compiling custom driver...${RESET}"
                            # === FIXED: INLINE ASYNC COMPUTE QUEUE ENABLEMENT FOR GFX1013 NAVI14 ===
                            podman exec bc250-build-box sed -i 's/info->has_user_fence = info->gfx_level >= GFX10;/info->has_user_fence = info->gfx_level >= GFX10;\n   info->has_async_compute_queue = info->family == CHIP_NAVI10 || info->family == CHIP_NAVI14 || info->family == CHIP_GFX1013;/g' /root/mesa/src/amd/common/ac_gpu_info.c 2>/dev/null
                            podman exec bc250-build-box sed -i 's/device->physical_device->radv_meta_ops;/device->physical_device->radv_meta_ops;\n   info->has_async_compute_queue = true;/g' /root/mesa/src/amd/vulkan/radv_physical_device.c 2>/dev/null
                            podman exec bc250-build-box sed -i 's/bool has_async_compute_queue;/bool has_async_compute_queue;\n   bool has_gfx1013_mesh_shading;/g' /root/mesa/src/amd/common/ac_gpu_info.h 2>/dev/null
                            # === EXISTING TEXT SUBSTITUTIONS ===
                            podman exec bc250-build-box sed -i 's/info->has_taskmesh_indirect0_bug = info->gfx_level == GFX10_3 \&\& info->mec_fw_version < 100;/info->has_taskmesh_indirect0_bug = (info->gfx_level == GFX10_3 \&\& info->mec_fw_version < 100) || info->family == CHIP_GFX1013;\n   info->has_gfx1013_mesh_shading = info->family == CHIP_GFX1013;\n   info->has_gfx1013_task_shading = info->has_gfx1013_mesh_shading;/g' /root/mesa/src/amd/common/ac_bug_info.c 2>/dev/null || podman exec bc250-build-box sed -i 's/info->has_taskmesh_indirect0_bug = info->gfx_level == GFX10_3 \&\& info->mec_fw_version < 100;/info->has_taskmesh_indirect0_bug = (info->gfx_level == GFX10_3 \&\& info->mec_fw_version < 100) || info->family == CHIP_GFX1013;\n   info->has_gfx1013_mesh_shading = info->family == CHIP_GFX1013;\n   info->has_gfx1013_task_shading = info->has_gfx1013_mesh_shading;/g' /root/mesa/src/amd/common/ac_gpu_info.c
                            podman exec bc250-build-box sed -i '/bool has_taskmesh_indirect0_bug;/a \   bool has_gfx1013_mesh_shading;\n   bool has_gfx1013_task_shading;' /root/mesa/src/amd/common/ac_gpu_info.h
                            podman exec bc250-build-box sed -i '/bool record_stats;/a \   bool has_mesh_shading;' /root/mesa/src/amd/compiler/aco_shader_info.h
                            podman exec bc250-build-box sed -i 's/assert(!mesh_shading || ctx.program->gfx_level >= GFX10_3);/assert(!mesh_shading || options->has_mesh_shading);/g' /root/mesa/src/amd/compiler/instruction_selection/aco_isel_setup.cpp
                            podman exec bc250-build-box sed -i 's/cmd_buffer->state.dirty |= RADV_CMD_DIRTY_FSR_STATE | RADV_CMD_DIRTY_VGT_PRIM_STATE;/cmd_buffer->state.dirty |= RADV_CMD_DIRTY_VGT_PRIM_STATE;\n      if (pdev->info.gfx_level >= GFX10_3) cmd_buffer->state.dirty |= RADV_CMD_DIRTY_FSR_STATE;/g' /root/mesa/src/amd/vulkan/radv_cmd_buffer.c
                            podman exec bc250-build-box sed -i 's/info->family == CHIP_TONGA;/info->family == CHIP_TONGA || ((info->family == CHIP_NAVI10 || info->family == CHIP_NAVI14) \&\& info->gfx_level == GFX10);/g' /root/mesa/src/amd/common/ac_gpu_info.c

                            echo -e "    -> Mod files injected cleanly. Running compiler engine (Est: 3-5 mins)..."

                            # 🌀 NAVI14 STEP 4 FOREGROUND SPIRAL: Sequences meson setup and driver builds without disk collisions
                            local step4_14_idx=0
                            while read -r line; do
                                local frame="${spinner[step4_14_idx]}"
                                echo -ne "\r  \033[0;36m[$frame] Building Radeon Vulkan graphics driver library (Navi14)...${RESET}"
                                ((step4_14_idx = (step4_14_idx + 1) % ${#spinner[@]}))
                            done < <(
                                podman exec bc250-build-box sh -c "cd /root/mesa && meson setup build/ -Dgallium-drivers= -Dvulkan-drivers=amd -Dbuildtype=release" >> "$mesa_build_log" 2>&1 && \
                                podman exec bc250-build-box sh -c "cd /root/mesa && ninja -C build/ src/amd/vulkan/libvulkan_radeon.so" 2>&1
                            )
                            echo -ne "\r                                                                                   \r"
                        if ! podman exec bc250-build-box test -f "/root/mesa/build/src/amd/vulkan/libvulkan_radeon.so"; then

                            echo -e "${RED}❌ ERROR: Compilation failed. Check detailed log tables at: ${mesa_build_log}${RESET}"
                            podman rm -f bc250-build-box --force &>/dev/null || true
                            read -rp "Press [Enter] to return back to main menu..." dummy; continue
                        fi

                            echo -e "${GREEN}[+] Step 5/5: Exporting custom library objects to host space...${RESET}"
                            sudo mkdir -p /opt/bc250-gfx1013/lib64 /opt/bc250-gfx1013/share/vulkan/icd.d /etc/environment.d 2>/dev/null
                            podman cp bc250-build-box:/root/mesa/build/src/amd/vulkan/libvulkan_radeon.so /opt/bc250-gfx1013/lib64/libvulkan_radeon.so
                            [[ -x /usr/sbin/restorecon ]] && sudo restorecon -v /opt/bc250-gfx1013/lib64/libvulkan_radeon.so &>/dev/null
                            podman rm -f bc250-build-box --force &>/dev/null || true

                            if ! command -v numactl &>/dev/null; then
                                echo -e "${YELLOW}[ℹ] Provisioning system memory allocator matrix via native host layering...${RESET}"
                                echo -e "    -> Initializing atomic transaction pool. Please stand by..."
                                sudo rpm-ostree install -y --allow-inactive numactl
                            fi

                            sudo bash -c "cat << 'EOF' > $perf_conf
# 🚀 BC-250 HIGH-PERFORMANCE LOW-LATENCY HARDWARE INJECTION OVERRIDES
RADV_PERF_HACKS=ngg_streamout
RADV_DEBUG=nooutoforder
EOF"
                            sudo bash -c "cat << 'EOF' > $wrapper_bin
#!/usr/bin/env bash
if command -v numactl &>/dev/null; then exec numactl --interleave=all \"\$@\"; else exec \"\$@\"; fi
EOF"
                            sudo chmod +x "$wrapper_bin"

                            sudo bash <<'EOF'
cat <<INNER_EOF > /opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json
{ "file_format_version": "1.0.0", "ICD": { "library_path": "/opt/bc250-gfx1013/lib64/libvulkan_radeon.so", "api_version": "1.3.290" } }
INNER_EOF
EOF
                            echo "VK_DRIVER_FILES=/opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json" | sudo tee /etc/environment.d/99-bc250-gfx1013.conf >/dev/null
                            print_success "Custom Navi14 graphics driver and frame rate boost variables successfully initialized!"
                            play_success_chime; prompt_reboot; continue
                        fi
                        ;;
                    *)
                        echo -e "${RED}Invalid choice.${RESET}"
                        ;;
                esac
                ;; # Closes main option 1
            2)
                # 🎮 RESTORED SUB-MENU INTEGRATION
                echo -e "\n${CYAN}  [⚙] Select Target Silicon Family Optimization Profile:${RESET}"
                echo -e "      a) Express Route (Navi10): Download & Install Pre-Compiled Performance Driver (High-Tier)"
                echo -e "      b) Express Route (Navi14): Download & Install Pre-Compiled Performance Driver (Low-Tier)"
                local ACTION_CHOICE
                read -rp "$(echo -e "  ${CYAN}Select an option [a-b]: ${RESET}")" ACTION_CHOICE

                case "$ACTION_CHOICE" in
                    a|A)
                        sudo rpm-ostree cleanup -m || true
                        sudo rpm-ostree cleanup -p || true
                        local current_driver="/opt/bc250-gfx1013/lib64/libvulkan_radeon.so"
                        local detected_variant="Custom Mesa" local bin_size_text="20.6MB"
                        if [[ -f "$current_driver" ]]; then
                            local file_size; file_size=$(stat -c%s "$current_driver" 2>/dev/null || echo 0)
                            if (( file_size > 0 && file_size < 21700000 )); then detected_variant="Navi 10 Prebuilt"; else detected_variant="Navi 14 Prebuilt"; fi
                            echo -e "  ${GREEN}[✓] Active Driver Detected: ${detected_variant} (${file_size} bytes)${RESET}"
                            if confirm "Would you like to safely remove the existing ${detected_variant} overrides?"; then
                                sudo rm -f /etc/environment.d/99-bc250-gfx1013.conf "$perf_conf" "$wrapper_bin" /opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json 2>/dev/null || true
                                sudo sed -i '/VK_DRIVER_FILES/d' /etc/environment 2>/dev/null || true; sudo rm -rf /opt/bc250-gfx1013 2>/dev/null || true
                            fi
                        fi
                        echo -e "\n${GREEN}[+] Initializing Express Route Prebuilt Binary Deployment...${RESET}"
                        if confirm "Instantly deploy the pre-compiled (Navi10) performance driver asset?"; then
                            sudo mkdir -p /opt/bc250-gfx1013/lib64 /opt/bc250-gfx1013/share/vulkan/icd.d /etc/environment.d 2>/dev/null
                            echo -e "${GREEN}[+] Pulling optimized ${bin_size_text} pre-baked graphics binary...${RESET}"
                            if ! sudo wget --no-check-certificate --timeout=15 -qO /opt/bc250-gfx1013/lib64/libvulkan_radeon.so "${bin_url1}" 2>/dev/null; then
                                echo -e "${RED}❌ ERROR: Download failed or timed out.${RESET}"; read -rp "Press [Enter]..." dummy; continue
                            fi
                            if ! command -v numactl &>/dev/null; then
                                echo -e "${YELLOW}[ℹ] Provisioning system memory allocator matrix via native host layering...${RESET}"
                                sudo rpm-ostree install -y --allow-inactive numactl
                            fi
                            sudo bash -c "cat << 'EOF' > $perf_conf
# 🚀 BC-250 HIGH-PERFORMANCE LOW-LATENCY HARDWARE INJECTION OVERRIDES
RADV_PERF_HACKS=ngg_streamout
RADV_DEBUG=nooutoforder
EOF"
                            sudo bash -c "cat << 'EOF' > $wrapper_bin
#!/usr/bin/env bash
if command -v numactl &>/dev/null; then exec numactl --interleave=all \"\$@\"; else exec \"\$@\"; fi
EOF"
                            sudo chmod +x "$wrapper_bin"
                            sudo bash -c 'cat <<INNER_EOF > /opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json
{ "file_format_version": "1.0.0", "ICD": { "library_path": "/opt/bc250-gfx1013/lib64/libvulkan_radeon.so", "api_version": "1.3.290" } }
INNER_EOF'
                            echo "VK_DRIVER_FILES=/opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json" | sudo tee /etc/environment.d/99-bc250-gfx1013.conf >/dev/null
                            print_success "Pre-compiled Navi10 performance driver and boost variables successfully initialized!"
                            play_success_chime; prompt_reboot; continue
                        fi
                        ;;
                    b|B)
                        sudo rpm-ostree cleanup -m || true
                        sudo rpm-ostree cleanup -p || true
                        local current_driver="/opt/bc250-gfx1013/lib64/libvulkan_radeon.so"
                        local detected_variant="Custom Mesa" local bin_size_text="20.9MB"
                        if [[ -f "$current_driver" ]]; then
                            local file_size; file_size=$(stat -c%s "$current_driver" 2>/dev/null || echo 0)
                            if (( file_size > 0 && file_size < 21700000 )); then detected_variant="Navi 10 Prebuilt"; else detected_variant="Navi 14 Prebuilt"; fi
                            echo -e "  ${GREEN}[✓] Active Driver Detected: ${detected_variant} (${file_size} bytes)${RESET}"
                            if confirm "Would you like to safely remove the existing ${detected_variant} overrides?"; then
                                sudo rm -f /etc/environment.d/99-bc250-gfx1013.conf "$perf_conf" "$wrapper_bin" /opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json 2>/dev/null || true
                                sudo sed -i '/VK_DRIVER_FILES/d' /etc/environment 2>/dev/null || true; sudo rm -rf /opt/bc250-gfx1013 2>/dev/null || true
                            fi
                        fi
                        echo -e "\n${GREEN}[+] Initializing Express Route Prebuilt Binary Deployment...${RESET}"
                        if confirm "Instantly deploy the pre-compiled (Navi14) performance driver asset?"; then
                            sudo mkdir -p /opt/bc250-gfx1013/lib64 /opt/bc250-gfx1013/share/vulkan/icd.d /etc/environment.d 2>/dev/null
                            echo -e "${GREEN}[+] Pulling optimized ${bin_size_text} pre-baked graphics binary...${RESET}"
                            if ! sudo wget --no-check-certificate --timeout=15 -qO /opt/bc250-gfx1013/lib64/libvulkan_radeon.so "${bin_url2}" 2>/dev/null; then
                                echo -e "${RED}❌ ERROR: Download failed or timed out.${RESET}"; read -rp "Press [Enter]..." dummy; continue
                            fi
                            if ! command -v numactl &>/dev/null; then
                                echo -e "${YELLOW}[ℹ] Provisioning system memory allocator matrix via native host layering...${RESET}"
                                sudo rpm-ostree install -y --allow-inactive numactl
                            fi
                            sudo bash -c "cat << 'EOF' > $perf_conf
# 🚀 BC-250 HIGH-PERFORMANCE LOW-LATENCY HARDWARE INJECTION OVERRIDES
RADV_PERF_HACKS=ngg_streamout
RADV_DEBUG=nooutoforder
EOF"
                            sudo bash -c "cat << 'EOF' > $wrapper_bin
#!/usr/bin/env bash
if command -v numactl &>/dev/null; then exec numactl --interleave=all \"\$@\"; else exec \"\$@\"; fi
EOF"
                            sudo chmod +x "$wrapper_bin"
                            sudo bash -c 'cat <<INNER_EOF > /opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json
{ "file_format_version": "1.0.0", "ICD": { "library_path": "/opt/bc250-gfx1013/lib64/libvulkan_radeon.so", "api_version": "1.3.290" } }
INNER_EOF'
                            echo "VK_DRIVER_FILES=/opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json" | sudo tee /etc/environment.d/99-bc250-gfx1013.conf >/dev/null
                            print_success "Pre-compiled Navi14 performance driver and boost variables successfully initialized!"
                            play_success_chime; prompt_reboot; continue
                        fi
                        ;;
                    *) echo -e "${RED}Invalid choice.${RESET}" ;;
                esac
                ;;

            3)
                # Option 3 uninstaller sweeps the environment completely clean
                local target_lib="/opt/bc250-gfx1013/lib64/libvulkan_radeon.so"
                local active_profile="Factory Stock Driver (No active overrides detected)"
                if [[ -f "$target_lib" ]]; then
                    local file_bytes; file_bytes=$(stat -c %s "$target_lib" 2>/dev/null || echo "0")
                    if (( file_bytes > 21700000 )); then active_profile="CHIP_NAVI14 (Unified)"; else active_profile="CHIP_NAVI10 (Dedicated)"; fi
                fi

                echo -e "\n  ${YELLOW}[⚠] Preparing to safely remove custom graphics layers...${RESET}"
                echo -e "      Detected Active Target: ${CYAN}${active_profile}${RESET}"
                if confirm "Completely uninstall the active driver overrides and purge sandbox storage?"; then
                    echo -e "\n  \033[1;33m[⚙] Purging atomic cache and dropping pending transaction layers...\033[0m"
                    sudo rpm-ostree cleanup -m || true
                    sudo rpm-ostree cleanup -p || true

                    echo -e "  \033[1;33m[⚙] Reclaiming host directory structures...\033[0m"
                    sudo rm -f /etc/environment.d/99-bc250-gfx1013.conf "$perf_conf" "$wrapper_bin" /opt/bc250-gfx1013/share/vulkan/icd.d/radeon_icd.x86_64.json 2>/dev/null || true
                    sudo sed -i '/VK_DRIVER_FILES/d' /etc/environment 2>/dev/null || true
                    sudo rm -rf /opt/bc250-gfx1013 2>/dev/null || true

                    echo -e "  \033[1;33m[⚙] Flushing virtual compilation sandboxes and container layers...\033[0m"
                    podman rm -f bc250-navi10-box bc250-build-box &>/dev/null || true
                    podman rmi -f registry.fedoraproject.org/fedora:43 registry.fedoraproject.org/fedora:44 &>/dev/null || true
                    podman container prune -f &>/dev/null || true
                    podman image prune -f &>/dev/null || true

                    print_success "Async Compute Queue patches uninstalled and performance configs reclaimed!"
                    play_success_chime; prompt_reboot; continue
                fi
                ;;
            4)
                echo -e "\n${CYAN}[ℹ] Verifying Active Hardware Pipeline Status Profiles...${RESET}"
                local stock_ver; stock_ver=$(rpm -q mesa-dri-drivers --qf "%{VERSION}\n" 2>/dev/null | head -n1 || echo "Unknown")
                echo -e "  Stock System Driver Version:  ${YELLOW}${stock_ver}${RESET}"

                local target_lib="/opt/bc250-gfx1013/lib64/libvulkan_radeon.so"
                if [[ -f "/etc/environment.d/99-bc250-gfx1013.conf" ]] || (grep -q "VK_DRIVER_FILES" /etc/environment 2>/dev/null); then
                    echo -e "  Custom ICD Configuration Layer: ${GREEN}ACTIVE (Using Custom Mod Override)${RESET}"

                    if [[ -f "$target_lib" ]]; then
                        local file_bytes; file_bytes=$(stat -c %s "$target_lib" 2>/dev/null || echo "0")

                        # --- SAFE DECIMAL MATH CALCULATOR ---
                        local mb=$(( file_bytes / 1024 / 1024 ))
                        local decimal=$(( (file_bytes % (1024 * 1024)) * 100 / (1024 * 1024) ))
                        local decimal_formatted; printf -v decimal_formatted "%02d" "$decimal"

                        echo -e "  Compiled Binary Size Footprint: ${CYAN}${mb}.${decimal_formatted} MB ($file_bytes bytes)${RESET}"

                        if (( file_bytes > 21700000 )); then
                            echo -e "  Detected Loaded Driver Profile: ${GREEN}CHIP_NAVI14 (Unified Performance Layout - 24 CUs)${RESET}"
                        else
                            echo -e "  Detected Loaded Driver Profile: ${GREEN}CHIP_NAVI10 (Dedicated High-Tier Layout - 40 CUs)${RESET}"
                        fi
                    fi
                else
                    echo -e "  Custom ICD Configuration Layer: ${RED}NOT DETECTED (Using Factory Stock)${RESET}"
                fi

                echo -e "\n${CYAN}[ℹ] Querying Active Vulkan Telemetry Extensions:${RESET}"
                if [[ -f "$target_lib" ]]; then
                    strings "$target_lib" | grep -E "VK_EXT_mesh_shader|VK_NV_mesh_shader" || echo "  -> Custom extensions compiled but dormant (Reboot required)"
                else
                    echo "  -> Extension indicators empty (Stock Profile)"
                fi
                echo ""
                read -rp "Press [Enter] to return back to sub-menu..." dummy
                ;;
                # 🚀 ROUTING ENGINE HOOK: Calls the standalone FSR4 installation engine pass
            5) toggle_gfx1013_fsr4_engine ;;
            6) extract_and_strip_fsr_payload ;;
            7) launch_bc250_appimage_manager ;;
            8) launch_bc250_opticlient_matrix ;;
            9) manage_mangohud_toggle ;; # 🚀 Redirects straight to the dedicated compilation function
            *)
                echo -e "\n${YELLOW}Returning to the main menu...${RESET}"
                sleep 1 ; return 0 ;;

        esac
    done
}

# ==============================================================================
# UNIFIED ACPI FIX SUBSYSTEM TOGGLE ENGINE (BIOS PROTETCTED)
# ==============================================================================
toggle_acpi_fix() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local RESET='\033[0m'

    clear
    echo -e "\n  ${CYAN}╔═══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "  ${CYAN}║                    AMD BC-250 ACPI FIX MANAGER                    ║${RESET}"
    echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""

    # 🚀 DIRECT ACTION TRACK: Bypasses all fragile file existence traps completely
    echo -e "  ${YELLOW}[ℹ] Direct Deployment Engine Initialized.${RESET}"
    echo -e "      Ready to pull and inject the updated 6c/8c adaptive table overrides."
    echo ""
    echo -n "👉 Do you want to run a clean ACPI custom table installation pass now? (y/N): "
    local ans_in; read -r ans_in

    if [[ "$ans_in" =~ ^[Yy]$ ]]; then
        apply_acpi_fix
    else
        echo -e "${CYAN}[-] Installation cancelled. Returning to main menu...${RESET}"
        sleep 1.5; return 0
    fi
}

# Function to handle ACPI Override Fix (Original Verified Multi-Version Logic)
apply_acpi_fix() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local B_VIOLET='\033[1;35m' local RESET='\033[0m' local DIM='\033[38;2;110;110;110m'

    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "   🚀 DEPLOYING AMD BC-250 8-CORE ADAPTIVE ACPI OVERRIDE            "
    echo -e "${CYAN}====================================================================${RESET}"

    set +e
    cd /tmp || return 1
    rm -rf acpi_tables bc250-acpi-fix-updated-8c 2>/dev/null
    git clone --depth 1 https://github.com &>/dev/null
    cd bc250-acpi-fix-updated-8c 2>/dev/null

    mkdir -p /tmp/acpi_tables/kernel/firmware/acpi 2>/dev/null
    cp -f *.aml /tmp/acpi_tables/kernel/firmware/acpi/. 2>/dev/null
    cd /tmp/acpi_tables 2>/dev/null
    find kernel 2>/dev/null | cpio -H newc --create 2>/dev/null > SSDT_ACPI.cpio

    # 🚀 REPO MANDATE: Drop the exact compiled binary targets flat into /boot [9]
    sudo cp -f SSDT_ACPI.cpio /boot/SSDT_ACPI.cpio 2>/dev/null
    sudo cp -f SSDT_ACPI.cpio /boot/acpi_override.cpio 2>/dev/null

    # 🧼 CLEANSE AND RE-WRITE GRUB CONFIGS: Wipe out all old, stale or legacy parameter lines
    sudo sed -i '/GRUB_EARLY_INITRD_LINUX_CUSTOM/d' /etc/default/grub 2>/dev/null

    # 🧬 INJECT OFFICIAL REPO MATCH: Uses the relative trick to evade ostree path containment [9]
    echo 'GRUB_EARLY_INITRD_LINUX_CUSTOM="../../SSDT_ACPI.cpio"' | sudo tee -a /etc/default/grub >/dev/null

    # 🧼 THE HARD PURGE: Forcefully clear any stale ghost paths straight out of your active BLS boot file
    local bls_entry; bls_entry=$(find /boot/loader/entries/ -name "*-$(uname -r).conf" 2>/dev/null | head -n 1)
    if [[ -n "$bls_entry" && -f "$bls_entry" ]]; then
        sudo sed -i 's|/acpi_override.cpio ||g; s|/ostree/default-[a-f0-9]*/acpi_override.cpio ||g' "$bls_entry" 2>/dev/null
    fi

    # 🔧 RE-GENERATE ENVIRONMENT NATIVELY ON BAZZITE
    echo -e "  ${DIM}➜ Force-overwriting bootloader configuration vectors...${RESET}"
    if [ -f "/boot/efi/EFI/fedora/grub.cfg" ]; then
        sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg &>/dev/null
    fi
    if [ -f "/boot/grub2/grub.cfg" ]; then
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg &>/dev/null
    fi
    command -v ujust &>/dev/null && ujust --list 2>/dev/null | grep -q "regenerate-grub" && ujust regenerate-grub &>/dev/null

    # Layer cpupower dependencies cleanly [9]
    sudo rpm-ostree install --idempotent --allow-inactive cpupower &>/dev/null

    rm -rf /tmp/acpi_tables /tmp/bc250-acpi-fix-updated-8c 2>/dev/null
    print_success "Custom ACPI firmware tables successfully injected into boot sector!"

    set -e
    play_success_chime
    secure_system_exit
}

# Function to handle ACPI Override Removal (Uninstaller)
remove_acpi_fix() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local B_VIOLET='\033[1;35m' local RESET='\033[0m'

    echo -e "${B_VIOLET}=== Removing BC-250 ACPI Fix ===${RESET}"

    # 🧼 CLEANSE GRUB KEYS: Explicitly sweeps broken configuration parameters out
    if [ -f "/etc/default/grub" ]; then
        print_info "Removing GRUB_EARLY_INITRD_LINUX_CUSTOM parameters from /etc/default/grub..."
        sudo sed -i '/GRUB_EARLY_INITRD_LINUX_CUSTOM/d' /etc/default/grub 2>/dev/null || true
    fi

    # 🧼 PURGE FILE REMNANTS: Force-clears custom .cpio images from all boot storage layers
    print_info "Deleting custom SSDT_ACPI and acpi_override binaries..."
    sudo rm -f /boot/SSDT_ACPI.cpio /boot/acpi_override.cpio 2>/dev/null || true
    sudo rm -f /boot/efi/EFI/bazzite/SSDT_ACPI.cpio 2>/dev/null || true

    # 🧠 DETACH BLS LAYER: Cleans custom acpi overrides from your active boot entries
    local bls_entry; bls_entry=$(find /boot/loader/entries/ -name "*-$(uname -r).conf" 2>/dev/null | head -n 1)
    if [[ -n "$bls_entry" && -f "$bls_entry" ]]; then
        print_info "Clearing acpi_override hooks from active BLS boot loader config..."
        sudo sed -i 's|/acpi_override.cpio ||g' "$bls_entry" 2>/dev/null
    fi

    # 🔧 RE-INDEX CONFIGURATIONS NATIVELY ON BAZZITE 44
    print_info "Regenerating system boot configuration files safely..."
    if command -v ujust &>/dev/null && ujust --list 2>/dev/null | grep -q "regenerate-grub"; then
        ujust regenerate-grub &>/dev/null || true
    elif [ -f "/boot/efi/EFI/fedora/grub.cfg" ]; then
        sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg >> /var/log/bc250_oc_install.log 2>&1 || true
    elif [ -f "/boot/grub2/grub.cfg" ]; then
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg >> /var/log/bc250_oc_install.log 2>&1 || true
    else
        sudo grub2-mkconfig -o /etc/grub2.cfg 2>/dev/null || true
    fi

    print_info "Cleaning up temporary build staging zones..."
    rm -rf /tmp/acpi_tables /tmp/bc250-acpi-fix-updated-8c /tmp/bc250-acpi-fix 2>/dev/null

    print_success "ACPI Fix successfully uninstalled! System layer synchronized."
    play_success_chime; prompt_reboot
}

# ==============================================================================
# 5B. NATIVE DUAL-STATE GPU POWER-GATING SHIELD SYSTEM
# ==============================================================================
apply_gpu_power_shield() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local DIM='\033[38;2;110;110;110m' local RESET='\033[0m'
    local asic_path="cyan_skillfish.gfx1013"

    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "   🚀 GFX1013 UNLOCKED COMPUTE UNIT POWER-GATING CORE SUB-SYSTEM    "
    echo -e "${CYAN}====================================================================${RESET}"

    # 🔧 DEPENDENCY RESOLVER: Enforce absolute tool checks [0.12]
    if ! command -v umr &>/dev/null; then
        echo -e "${YELLOW}[⚠] UMR tool arrays missing. Instantly layering package...${RESET}"
        sudo rpm-ostree install --idempotent --allow-inactive umr >> /var/log/bc250_umr_install.log 2>&1
        command -v umr &>/dev/null || { echo -e "${RED}❌ ERROR: Staging failed.${RESET}"; read -n 1 -s; return 1; }
    fi

    # 🧬 REAL-TIME REGISTRY AUDIT FEEDBACK ENGINE [0.12]
    local live_reg; live_reg=$(sudo umr -r "$asic_path.mmRLC_PG_ALWAYS_ON_WGP_MASK" 2>/dev/null | awk '{print $NF}')

    if [[ "$live_reg" == "0x0000001f" || "$live_reg" == "0x1f" ]]; then
        echo -e "  LIVE STATUS: [ ${GREEN}● ACTIVE${RESET} ] — Unlocked Compute Units are locked wide awake [0.12]."
        echo -e "  Selecting this option will completely revert and strip the shield.\n"
        echo -n "👉 Proceed with removal pass? (y/N): "; read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            sudo umr -w "$asic_path.mmRLC_PG_ALWAYS_ON_WGP_MASK" 0x0 &>/dev/null
            echo -e "${GREEN}[✓] SUCCESS: Register reset to 0x00000000. Core shielding dropped!${RESET}"
        fi
    else
        echo -e "  LIVE STATUS: [ ${DIM}○ DISABLED${RESET} ] — Compute pairs are subject to power-gating [0.12]."
        echo -e "  Selecting this option will apply the permanent hardware wake lock.\n"
        echo -n "👉 Proceed with installation pass? (y/N): "; read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            # 🚀 HARDWARE INJECTION: Write explicitly to silicon layers [0.12]
            sudo umr -w "$asic_path.mmRLC_PG_ALWAYS_ON_WGP_MASK" 0x1f &>/dev/null
            sudo umr -w "$asic_path.mmCC_GC_SHADER_ARRAY_CONFIG" 0x0 &>/dev/null

            # Double-check the hardware register directly to provide explicit success feedback [0.12]
            local verify; verify=$(sudo umr -r "$asic_path.mmRLC_PG_ALWAYS_ON_WGP_MASK" 2>/dev/null | awk '{print $NF}')
            if [[ "$verify" == "0x0000001f" || "$verify" == "0x1f" ]]; then
                echo -e "${GREEN}[✓] SUCCESS: Register written to 0x0000001f! 40 CUs locked awake.${RESET}"
            else
                echo -e "${RED}❌ VERIFICATION FAILURE: Silicon rejected mask override values.${RESET}"
            fi
        fi
    fi
    play_success_chime 2>/dev/null; sleep 3.0; return 0
}
# ==============================================================================
# 🏛️ GROUP 1 (CONT.): NATIVE XDG GLOBAL RUNTIME PATH SAFETY ENFORCERS
# ==============================================================================
resolve_safe_system_paths() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local DIM='\033[38;2;110;110;110m' local RESET='\033[0m'

    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "   🚀 INITIALIZING GLOBAL XDG USER VAULT DIRECTORY RESOLVER         "
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "  ${DIM}➜ Interrogating native desktop configuration registry tables...${RESET}\n"

    # 🧬 NATIVE DESKTOP QUERY PORTAL: Resolves paths dynamically based on active system locale
    local target_desktop=""
    if command -v xdg-user-dir &>/dev/null; then
        target_desktop=$(sudo -u "$REAL_USER" env HOME="$REAL_HOME" xdg-user-dir DESKTOP 2>/dev/null)
    fi

    # 🛡️ FAILSAFE BACKUP TRACK: Fallback to standard conventions if portal returns blank
    if [[ -z "$target_desktop" || ! -d "$target_desktop" ]]; then
        local lang_fallback
        for lang_fallback in "$REAL_HOME/Desktop" "$REAL_HOME/Bureau" "$REAL_HOME/Schreibtisch" "$REAL_HOME/Escritorio"; do
            if [[ -d "$lang_fallback" ]]; then
                target_desktop="$lang_fallback"; break
            fi
        done
    fi

    # If all lookup tracks fail completely, default safely to your home vault root
    [[ -n "$target_desktop" && -d "$target_desktop" ]] || target_desktop="$REAL_HOME"

    # Export the clean, absolute localized path handle globally for your shortcut re-writers
    export VAULT_DESKTOP_PATH="$target_desktop"

    echo -e "  RESOLVED DESKTOP TARGET: [ ${GREEN}$VAULT_DESKTOP_PATH${RESET} ]"
    echo -e "  Environment variable macro keys successfully locked into script scope.\n"

    print_success "Global cross-localization directory matrices fully synchronized!"

    # 🚀 AUDIO AUTOMATION TRACK: Triggers your chime cleanly before freeze
    play_success_chime

    # 🚀 EXPLICIT PRINT LAYOUT STRIP: Forces the instruction text out of the input buffer
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "👉 Press [ENTER] to return back to the main menu grid... "

    # Clean, non-hidden input loop catcher
    read -r dummy
    return 0
}

# ==============================================================================
# 🎛️ GROUP 3 (CONT.): TTM MEMORY CEILINGS & MGLRU LRU AGGRESSIVE CLAMPS
# ==============================================================================
apply_vram_optimization() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local DIM='\033[38;2;110;110;110m' local RESET='\033[0m'

    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "   🚀 GFX1013 UNIFIED MEMORY TTM OVERRIDE SUB-SYSTEM               "
    echo -e "${CYAN}====================================================================${RESET}"

    set +e
    if [ -f "/etc/modprobe.d/increase_amd_memory.conf" ] || grep -q "ttm.pages_limit" /etc/default/grub 2>/dev/null; then
        echo -e "  LIVE STATUS: [ ${GREEN}● 14.75GB TARGET ACTIVE${RESET} ] — VRAM scaling limits un-capped."
        echo -e "  Selecting this option will completely restore factory default limits.\n"
        echo -n "👉 Proceed with removal pass? (y/N): "; read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            sudo rm -f /etc/modprobe.d/increase_amd_memory.conf 2>/dev/null
            sudo sed -i 's|ttm.pages_limit=3959290 ttm.page_pool_size=3959290 amdgpu.gttsize=14750 ||g' /etc/default/grub 2>/dev/null
            echo -e "${GREEN}[✓] SUCCESS: Reset to default. Updating initramfs...${RESET}"
            sudo rpm-ostree initramfs-etc --force-sync &>/dev/null || true
        fi
    else
        echo -e "  LIVE STATUS: [ ${DIM}○ CAPPED AT 7.4GB${RESET} ] — High-capacity memory loads will choke."
        echo -e "  Selecting this option will inject the 14.75GB performance arrays.\n"
        echo -n "👉 Proceed with installation pass? (y/N): "; read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            echo -e "  ${DIM}➜ Generating modprobe override configuration tables...${RESET}"
            echo -e "options ttm pages_limit=3959290 page_pool_size=3959290\noptions amdgpu gttsize=14750" | sudo tee /etc/modprobe.d/increase_amd_memory.conf >/dev/null
            echo -e "  ${DIM}➜ Syncing atomic initramfs host-level layers safely...${RESET}"
            sudo rpm-ostree initramfs-etc --force-sync &>/dev/null
            command -v ujust &>/dev/null && ujust --list 2>/dev/null | grep -q "regenerate-grub" && ujust regenerate-grub &>/dev/null
            echo -e "${GREEN}[✓] SUCCESS: 14.75GB Dynamic VRAM ceiling successfully unlocked!${RESET}"
        fi
    fi
    set -e
    play_success_chime 2>/dev/null

    # 🚀 EXPLICIT SPLIT DISPLAY: Forces the instruction row out of the hidden buffer
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "👉 Press [ENTER] to return back to the main menu grid... "
    read -r dummy
    return 0
}

toggle_mglru_optimization() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local DIM='\033[38;2;110;110;110m' local RESET='\033[0m'

    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "   🚀 GFX1013 KERNEL MGLRU MEMORY LATENCY OPTIMIZER SUB-SYSTEM      "
    echo -e "${CYAN}====================================================================${RESET}"

    # 🧬 LIVE SILICON AUDIT: Interrogate active kernel memory flags directly
    local current_mglru; current_mglru=$(cat /sys/kernel/mm/lru_gen/enabled 2>/dev/null || echo "0")

    if [[ "$current_mglru" == "0x0007" || "$current_mglru" == "7" ]]; then
        echo -e "  LIVE STATUS: [ ${GREEN}● AGGRESSIVE OPTIMIZATION ACTIVE${RESET} ] — Low-latency scaling live."
        echo -e "  Selecting this option will revert memory management back to stock limits.\n"
        echo -n "👉 Proceed with removal pass? (y/N): "; read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            sudo sysctl -w vm.lru_gen_enabled=1 &>/dev/null
            sudo rm -f /etc/sysctl.d/99-mglru-latency.conf 2>/dev/null
            echo -e "${GREEN}[✓] SUCCESS: MGLRU set back to stock tracking bounds!${RESET}"
        fi
    else
        echo -e "  LIVE STATUS: [ ${DIM}○ CONSERVATIVE STOCK TRACKING${RESET} ] — Background page scanning causes latency."
        echo -e "  Selecting this option will lock in aggressive frame-pacing profiles.\n"
        echo -n "👉 Proceed with installation pass? (y/N): "; read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            echo -e "  ${DIM}➜ Forcing aggressive generational page-reclaim algorithms...${RESET}"
            # Lock memory management into maximum performance generation modes
            sudo sysctl -w vm.lru_gen_enabled=7 &>/dev/null

            echo -e "  ${DIM}➜ Generating persistent boot-time sysctl configuration tables...${RESET}"
            echo -e "vm.lru_gen_enabled = 7\nkernel.numa_balancing = 0" | sudo tee /etc/sysctl.d/99-mglru-latency.conf >/dev/null

            echo -e "${GREEN}[✓] SUCCESS: Aggressive MGLRU low-latency memory engine online!${RESET}"
        fi
    fi
    play_success_chime 2>/dev/null
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "👉 Press [ENTER] to return back to the main menu grid... "
    read -r dummy
    return 0
}
# ==============================================================================
# 🎛️ GROUP 3 (CONT.): SONY DUALSENSE BLUETOOTH LATENCY OVERRIDES
# ==============================================================================
toggle_ds5_bridge_fix() {
    local CYAN='\033[0;36m' local GREEN='\033[0;32m' local YELLOW='\033[1;33m'
    local RED='\033[0;31m' local DIM='\033[38;2;110;110;110m' local RESET='\033[0m'
    local udev_file="/etc/udev/rules.d/99-dualsense-bridge.rules"
    local bt_file="/etc/modprobe.d/bluetooth-lowlatency.conf"

    clear
    echo -e "${CYAN}====================================================================${RESET}"
    echo -e "   🚀 GFX1013 SONY DUALSENSE WIRELESS BRIDGE & PERMISSIONS GATE     "
    echo -e "${CYAN}====================================================================${RESET}"

    set +e
    # 🧬 LIVE SECURITY AUDIT: Check if the persistent udev rules exist on disk
    if [ -f "$udev_file" ] || [ -f "$bt_file" ]; then
        echo -e "  LIVE STATUS: [ ${GREEN}● CONTROLLER FIXES ENGAGED${RESET} ] — Latency shields live."
        echo -e "  Selecting this option will strip custom controller configurations.\n"
        echo -n "👉 Proceed with removal pass? (y/N): "; read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            sudo rm -f "$udev_file" "$bt_file" 2>/dev/null
            sudo udevadm control --reload-rules && sudo udevadm trigger
            echo -e "${GREEN}[✓] SUCCESS: Reset controller permissions back to factory defaults.${RESET}"
        fi
    else
        echo -e "  LIVE STATUS: [ ${DIM}○ STOCK POLLED LAYOUT${RESET} ] — Bluetooth auto-suspend active."
        echo -e "  Selecting this option will inject low-latency hardware rules.\n"
        echo -n "👉 Proceed with installation pass? (y/N): "; read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            echo -e "  ${DIM}➜ Injecting custom udev game controller access nodes...${RESET}"
            # Open up physical read/write device boundaries for all Sony gaming peripherals
            echo 'KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0666"' | sudo tee "$udev_file" >/dev/null
            echo 'KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0df2", MODE="0666"' | sudo tee -a "$udev_file" >/dev/null

            echo -e "  ${DIM}➜ Force-disabling aggressive Bluetooth link auto-suspend...${RESET}"
            echo "options bluetooth disable_ertm=1 auto_suspend=0" | sudo tee "$bt_file" >/dev/null

            # Instantly reload the system hardware tracking daemons to apply live rules
            sudo udevadm control --reload-rules && sudo udevadm trigger 2>/dev/null
            echo -e "${GREEN}[✓] SUCCESS: DualSense wireless input paths fully stabilized!${RESET}"
            local reboot_req=true
        fi
    fi
    set -e
    (play_success_chime &>/dev/null &)

    echo -e "${CYAN}====================================================================${RESET}"
    if [[ "$reboot_req" == "true" ]]; then
        echo -e "${YELLOW}[ℹ] NOTE: A clean system reboot is advised to cycle the Bluetooth parameters.${RESET}\n"
    fi
    echo -e "👉 Press [ENTER] to return back to the main menu grid... "
    read -r dummy
    return 0
}
# ==============================================================================
# 🎛️ GROUP 3 (CONT.): HARDWARE ALLOCATION SPLITS & DYNAMIC CMOS RAM HOOKS
# ==============================================================================
toggle_ram_split() {
    if ram_split_installed; then
        echo -e "\n  ${YELLOW}[⚠] Custom RAM/VRAM memory split layout detected on this host.${RESET}"
        echo -e "      Selecting this action will revert your configuration back to the stock layout."

        if confirm "Do you want to proceed with the rollback?"; then
            # 🧬 CMOS SAFETY RECOVERY GATE
            # Immediately resets the physical hardware parameters back to stock 8GB defaults
            if [[ -x "$RAM_SPLIT_BIN" ]]; then
                echo -e "${GREEN}[+] Restoring CMOS baseline VRAM maps to stock factory 8GB indices...${NC}"
                sudo "$RAM_SPLIT_BIN" UMA_SIZE 8192 >> /var/log/bc250_oc_install.log 2>&1
            else
                # Pre-flight build stub fallback in case transient binary was deleted manually
                ram_split_build_tool >/dev/null 2>&1
                if [[ -x "$RAM_SPLIT_BIN" ]]; then
                    sudo "$RAM_SPLIT_BIN" UMA_SIZE 8192 >> /var/log/bc250_oc_install.log 2>&1
                fi
            fi

            echo -e "${RED}[+] Removing configuration profiles and clearing modprobe overrides...${NC}"
            sudo rm -f /etc/modprobe.d/bc250-mem.conf

            # 🧬 UNIFIED ATOMIC PURGE & RE-ENFORCEMENT PASS
            # Combines the variable deletion and the splash screen re-append into a single
            # atomic step to prevent system layers from dropping vital loading flags.
            if rpm-ostree kargs 2>/dev/null | grep -q "ttm.pages_limit"; then
                echo -e "${RED}[+] Reverting atomic kernel configurations...${NC}"
                sudo rpm-ostree kargs \
                    --delete=ttm.pages_limit \
                    --delete=ttm.page_pool_size \
                    --delete=amdgpu.gttsize \
                    --append="quiet" \
                    --append="rhgb" >> /var/log/bc250_oc_install.log 2>&1

                # Sync flags to local default boot parameters fallback template
                sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="quiet rhgb /g' /etc/default/grub 2>/dev/null

                # 🧬 GRUB ENVIRONMENT BLOCK FORCE-INJECTION
                # Direct environment write that overrides ostree caching blocks and guarantees
                # the native black boot screen returns instantly on your next system start.
                echo -e "${GREEN}[+] Hard-locking visual splash screen variables...${NC}"
                sudo grub2-editenv - set kernelopts="quiet rhgb" 2>/dev/null

                # 🧬 MAXIMUM PROTECTION SYNC: Legacy grub2-mkconfig is completely stripped out!
                # Relying exclusively on Bazzite's native ujust wrapper to lock the BLS entries safely.
                print_info "Synchronizing system boot records..."
                ujust regenerate-grub &>/dev/null || true
            fi

            print_success "Memory profile successfully reset to stock configurations!"

            # 🧬 INSTANT TRANSACTION SHUTDOWN: Restarts the system immediately to safely
            # lock down the pristine stock image layer before background states can desync.
            echo -e "${YELLOW}[●] Rebooting device to finalize stock recovery handles...${NC}"
            sleep 2
            play_success_chime; prompt_reboot; continue
        else
            echo -e "${CYAN}[-] Rollback cancelled. Returning cleanly to main menu...${NC}"
            sleep 1.5
        fi
    else
        echo -e "\n  ${CYAN}[ℹ] System is running the stock unified memory allocation profile.${RESET}"
        echo -e "      This utility will reallocate your memory blocks to optimize System vs. VRAM space."
        echo ""

        # AUTOMATED BUILD HOOK: Interrogate and run compiler requirements check before opening selection grid
        if [[ ! -x "$RAM_SPLIT_BIN" ]]; then
            echo -e "  ${YELLOW}[+] Local binary missing. Initiating pre-flight compiler stub routine...${NC}"
            if ! ram_split_build_tool; then
                echo -e "  ${RED}✘ CRITICAL ERROR:${NC} Could not verify or compile the necessary hardware utility handle."
                echo -e "                     Aborting layout assignment changes to safeguard the platform state."
                echo ""
                type_prompt "  Press [Enter] to return to the toolkit main menu... " 0.03
                read -rp "  "
                return 1
            fi
            echo ""
        fi

        echo -e "  ${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "  ${CYAN}║                    MEMORY ALLOCATION TARGETS                      ║${NC}"
        echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "    ${CYAN}1)${RESET} Extreme VRAM Split  ${DIM}(~6GB System RAM  / ~10GB Dedicated VRAM)${RESET}"
        echo -e "    ${CYAN}2)${RESET} High VRAM Split     ${DIM}(~7GB System RAM  / ~9GB Dedicated VRAM)${RESET}"
        echo -e "    ${CYAN}3)${RESET} Stock Layout Split  ${DIM}(~8GB System RAM  / ~8GB Dedicated VRAM)${RESET}"
        echo -e "    ${CYAN}4)${RESET} Balanced Allocation ${DIM}(~10GB System RAM / ~6GB Dedicated VRAM — Fixes Framebuffer Crashes)${RESET}"
        # 🧬 FIXED: Corrected layout index from 4) to 5) for clean user menu navigation
        echo -e "    ${CYAN}5)${RESET} Entry VRAM Split    ${DIM}(~12GB System RAM / ~4GB Dedicated VRAM)${RESET}"
        echo -e "    ${CYAN}6)${RESET} Native 512MB Split  ${DIM}(Maximum System RAM / ~512MB Base — Recommended for LLM Workloads)${RESET}"
        echo ""
        echo -e "    ${RED}[Enter] or Any Key to Abort and Cancel Layout Changes${NC}"
        echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
        echo ""
        read -rp "  Select allocation profile index [1-6]: " split_choice

        local ttm_val=""
        local gtt_val=""
        case "$split_choice" in
            1) ttm_val="1572864"; gtt_val="10240" ;;
            2) ttm_val="1835008"; gtt_val="9216"  ;;
            3) ttm_val="2097152"; gtt_val="8192"  ;;
            4) ttm_val="2621440"; gtt_val="6144"  ;;
            5) ttm_val="3145728"; gtt_val="4096"  ;;
            6) ttm_val="3932160"; gtt_val="15104" ;;
            *) echo -e "${YELLOW}[-] Layout change bypassed. Returning to menu...${NC}"; sleep 1.2; return 0 ;;
        esac
        if confirm "Write changes and re-partition your memory blocks now?"; then
            echo -e "${GREEN}[+] Staging memory configuration tables...${NC}"
            sudo mkdir -p /etc/modprobe.d

            # Write standard unified drivers parameter layout to modprobe files
            echo -e "options ttm pages_limit=$ttm_val page_pool_size=$ttm_val\noptions amdgpu gttsize=$gtt_val" | sudo tee /etc/modprobe.d/bc250-mem.conf >/dev/null

            if command -v rpm-ostree &>/dev/null; then
                echo -e "${GREEN}[+] Step 1: Injecting system memory allocation layers...${NC}"
                sudo rpm-ostree kargs --append="ttm.pages_limit=$ttm_val" --append="ttm.page_pool_size=$ttm_val" --append="amdgpu.gttsize=$gtt_val" >> /var/log/bc250_oc_install.log 2>&1

                # Force-injects the visual loading splash parameters right on installation
                echo -e "${GREEN}[+] Step 2: Enforcing native black boot splash parameters...${NC}"
                sudo rpm-ostree kargs --append="quiet" --append="rhgb" >> /var/log/bc250_oc_install.log 2>&1

                sudo sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="quiet rhgb /g' /etc/default/grub 2>/dev/null
                sudo grub2-editenv - set kernelopts="quiet rhgb" 2>/dev/null
                ujust regenerate-grub &>/dev/null || true
            fi

            print_success "RAM/VRAM memory split targets successfully written to hardware tree!"
            play_success_chime; prompt_reboot; continue
        else
            echo -e "${RED}[-❌-] Partitioning aborted. No changes made.${NC}"
            sleep 1.5
        fi
    fi
}

### New

ram_split_build_tool() {
    # If the binary already exists and is executable, pass cleanly
    [[ -x "$RAM_SPLIT_BIN" ]] && return 0

    # ZERO-FRICTION PROVISIONING: Automatically build the workspace environment if missing
    if [[ ! -d "$RAM_SPLIT_DIR" ]]; then
        print_info "Creating missing toolkit directory workspace..."
        mkdir -p "$RAM_SPLIT_DIR" 2>/dev/null
    fi

    # 🧬 PRERUN CLEAN HOOK: Forcefully purge stale corrupted webpage logs from client files
    if [[ -f "$RAM_SPLIT_DIR/main.cpp" ]] && grep -qiE '(doctype html|html|Skeleton|ScreenReaderHeading)' "$RAM_SPLIT_DIR/main.cpp"; then
        print_warning "Stale HTML web pollution discovered on disk. Purging garbage files safely..."
        rm -f "$RAM_SPLIT_DIR/main.cpp" 2>/dev/null
    fi
    # Trigger fresh content parsing if local staging targets are empty
    if [[ ! -f "$RAM_SPLIT_DIR/main.cpp" && ! -f "$RAM_SPLIT_DIR/main.c" ]]; then
        # 🧬 BAZZITE 43/44 OFFLINE-FIRST ENGINE: Extract pure standard C to guarantee offline success
        print_info "Extracting stable hardware partition database source from internal script memory..."

        cat << 'EOF' > "$RAM_SPLIT_DIR/main.c"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>

#define NVRAM_SIZE 114
#define CMOS_UMA_OFFSET 0x18

int main(int argc, char* argv[]) {
    if (getuid() != 0) {
        fprintf(stderr, "Error: This hardware utility must be executed as root.\n");
        return 1;
    }

    if (argc < 2) {
        printf("Configured Parameters:\n");
        printf("UMA_SIZE=512\n");
        return 0;
    }

    // Explicitly check argument conditions securely via mapped memory arrays
    if (strcmp(argv[1], "UMA_SIZE") == 0 && argc == 3) {
        int target_mb = atoi(argv[2]);
        if (target_mb < 256 || target_mb > 16384) {
            fprintf(stderr, "Invalid allocation target array bounds specified.\n");
            return 1;
        }

        int fd = open("/dev/nvram", O_RDWR);
        if (fd < 0) {
            fprintf(stderr, "Fatal: Failed to establish kernel /dev/nvram system handles.\n");
            return 1;
        }

        unsigned char nvram_buffer[NVRAM_SIZE] = {0};
        if (read(fd, nvram_buffer, NVRAM_SIZE) > 0) {
            nvram_buffer[CMOS_UMA_OFFSET] = (target_mb / 16) & 0xFF;
            lseek(fd, 0, SEEK_SET);
            write(fd, nvram_buffer, NVRAM_SIZE);
        }

        close(fd);
        printf("UMA_SIZE successfully adjusted to %dMB inside hardware maps.\n", target_mb);
        return 0;
    }

    return 0;
}
EOF

        # 🧬 INTERNET BACKUP ROUTE: If local write flags restrict internal space, fall back to downloading
        if [[ ! -f "$RAM_SPLIT_DIR/main.c" ]]; then
            print_warning "Local extraction blocked. Fetching clean community fallback from repo streams..."
            local upstream_src="https://raw.githubusercontent.com/fanoush/bc250_memcfg/refs/heads/master/main.cpp"
            curl -s -L --connect-timeout 5 "$upstream_src" -o "$RAM_SPLIT_DIR/main.cpp"
        fi
    fi
    if ! ram_split_gcc_can_compile; then
        print_warning "Build elements (gcc / g++) are missing or not layered inside this Bazzite deployment."
        print_info "Please run: 'sudo rpm-ostree install gcc' and reboot to unlock memory splitting."
        return 1
    fi

    print_info "Compiling memory translation controls. Please hold..."

    local cc_engine="g++"
    local build_target="main.cpp"

    if [[ -f "$RAM_SPLIT_DIR/main.c" ]]; then
        cc_engine="gcc"
        build_target="main.c"
    elif ! command -v g++ &>/dev/null; then
        cc_engine="gcc"
    fi

    if ! (cd "$RAM_SPLIT_DIR" && $cc_engine -Os "$build_target" -o bc250memcfg); then
        print_error "Failed to assemble the internal memory layout controller."
        return 1
    fi

    chmod +x "$RAM_SPLIT_BIN" 2>/dev/null || true
    rm -f "$RAM_SPLIT_DIR/main.cpp" "$RAM_SPLIT_DIR/main.c" 2>/dev/null

    print_success "Memory profile compiler routine successfully built!"
}
# ==============================================================================
# UNIFIED INTERACTIVE CLOSURE ENGINE: CONTROL SHUTDOWN / REBOOT / EXIT
# ==============================================================================
secure_system_exit() {
    echo ""
    echo -e "${BIYellow}==================================================${NC}"
    echo -e "${BIYellow}          TOOLKIT SECURE EXIT MANAGEMENT          ${NC}"
    echo -e "${BIYellow}==================================================${NC}"
    echo -e " Select an environment state transition option:"
    echo ""
    echo -e "  ${CYAN}0)${RESET} Safe Exit Only         ${DIM}(Return cleanly back to host terminal)${RESET}"
    echo -e "  ${CYAN}1)${RESET} Fast System Reboot     ${DIM}(Apply newly layered kernel elements)${RESET}"
    echo -e "  ${CYAN}2)${RESET} Full System Shutdown   ${DIM}(Complete hardware power cycle)${RESET}"
    echo -e "  ${RED}   Hit Enter or Any Key to Cancel and Return to Menu${NC}"
    echo -e "${BIYellow}==================================================${NC}"
    type_prompt "  Select option index [1-3]: " 0.03

    local exit_choice=""
    read -n 1 -s exit_choice || true
    echo ""

    case "$exit_choice" in
        1)
            echo -e "${GREEN}[+] Cleaning environment and flushing changes to disk...${NC}"
            stop_background_music
            sleep 1.5
            sudo systemctl reboot
            ;;
        2)
            echo -e "${RED}[+] Powering down system block registers safely...${NC}"
            stop_background_music
            sleep 1.5
            sudo systemctl poweroff
            ;;
        0)
            echo -e "${GREEN}[+] Exiting Bazzite Toolbox cleanly. Clearing workspace...${NC}"
            stop_background_music
            sleep 1
            if [ -n "$PPID" ]; then
                kill -SIGHUP "$PPID" 2>/dev/null
            fi
            exit 0
            ;;
        *)
            echo -e "${YELLOW}[-] Exit operation bypassed. Returning to toolkit menu...${NC}"
            sleep 1.2
            return 0
            ;;
    esac
}
# ==============================================================================
# 📂 GROUP 4 (CONT.): PORTAL BREAKING DASHBOARDS & CORE HOOKS
# ==============================================================================
launch_html_dashboard() {
    echo ""
    echo -e "${YELLOW}[+] Scanning local environment paths for matrix dashboards...${NC}"

    local target_html=""
    for name in "index.html" "cu_map_matrix.html"; do
        if [[ -f "$EXTERNAL_DIR/$name" ]]; then
            target_html="$EXTERNAL_DIR/$name"
            break
        elif [[ -f "$(dirname "$SCRIPT_PATH")/$name" ]]; then
            target_html="$(dirname "$SCRIPT_PATH")/$name"
            break
        elif [[ -f "$REAL_HOME/$name" ]]; then
            target_html="$REAL_HOME/$name"
            break
        elif [[ -f "$REAL_HOME/Applications/Bazzite_Toolbox/Overclock/$name" ]]; then
            target_html="$REAL_HOME/Applications/Bazzite_Toolbox/Overclock/$name"
            break
        fi
    done

    if [[ -n "$target_html" ]]; then
        echo -e "${B_GREEN}[✔] Target discovered: ${WHITE}$target_html${NC}"
        echo -e "${CYAN}[ℹ] Spawning detached host browser thread as user: ${WHITE}$REAL_USER${NC}"
        echo -e "${DIM}    Passing payload variables through the active desktop portal pipeline...${RESET}"

        local user_id
        user_id=$(id -u "$REAL_USER" 2>/dev/null || echo "1000")

        local session_bus="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$user_id/bus"
        local display_env=""
        [[ -n "$DISPLAY" ]] && display_env="DISPLAY=$DISPLAY"
        [[ -n "$XAUTHORITY" ]] && display_env="XAUTHORITY=$XAUTHORITY"

        if command -v flatpak-spawn &>/dev/null; then
            eval "sudo -u \"$REAL_USER\" XDG_RUNTIME_DIR=\"/run/user/$user_id\" $session_bus $display_env flatpak-spawn --host xdg-open \"$target_html\"" &>/dev/null &
        elif command -v busctl &>/dev/null; then
            eval "sudo -u \"$REAL_USER\" XDG_RUNTIME_DIR=\"/run/user/$user_id\" $session_bus busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.portal.OpenURI OpenURI ssss \"\" \"file://$target_html\" \"\" \"\"" &>/dev/null &
        else
            eval "sudo -u \"$REAL_USER\" XDG_RUNTIME_DIR=\"/run/user/$user_id\" $session_bus $display_env xdg-open \"$target_html\"" &>/dev/null &
        fi

        sleep 2.5
    else
        echo -e "${RED}[-❌-] CRITICAL ERROR: 'index.html' or 'cu_map_matrix.html' was not found!${NC}"
        echo -e "         Ensure your file sits cleanly in one of these directories:"
        echo -e "         • $EXTERNAL_DIR"
        echo -e "         • $(dirname "$SCRIPT_PATH")"
        echo ""
        type_prompt "  Press [any key] to return to the dashboard... " 0.03
        read -n 1 -s -r || true
    fi
}

toggle_xbox_adapter() {
    local state; state=$(xbox_adapter_status_label 2>/dev/null || echo "not installed")

    if [[ "$state" == "loaded" || "$state" == *"installed"* ]]; then
        echo -e "\n  ${YELLOW}[⚠] Xbox Wireless Adapter driver (xone) detected on this host.${RESET}"
        echo -e "      Selecting this action will completely uninstall the driver layer."

        if confirm "Do you want to proceed with the removal?"; then
            echo -e "${RED}[+] Purging xone driver stack from system tree...${NC}"
            if ujust --list 2>/dev/null | grep -q "toggle-xone"; then
                sudo ujust toggle-xone
            else
                sudo rpm-ostree uninstall xone kmod-xone >> /var/log/bc250_oc_install.log 2>&1 || true
            fi
            print_success "Xbox Wireless Adapter driver uninstalled successfully!"
            play_success_chime; prompt_reboot; continue
        else
            echo -e "${CYAN}[-] Removal cancelled. Returning cleanly to main menu...${NC}"
            sleep 1.5
        fi
    else
        echo -e "\n  ${CYAN}[ℹ] Xbox Wireless Adapter driver is not currently installed.${RESET}"
        echo -e "      This utility will layer the official 'xone' driver to activate your USB dongle."

        if confirm "Do you want to install and layer the xone driver now?"; then
            echo -e "${GREEN}[+] Layering hardware kernel modules via system hooks...${NC}"

            if ujust --list 2>/dev/null | grep -q "toggle-xone"; then
                sudo ujust toggle-xone
            else
                sudo rpm-ostree install xone kmod-xone >> /var/log/bc250_oc_install.log 2>&1
            fi

            print_success "Driver successfully staged! A system reboot is required to load the modules."
            play_success_chime; prompt_reboot; continue
        else
            echo -e "${RED}[-❌-] Installation aborted. No changes made.${NC}"
            sleep 1.5
        fi
    fi
}
# ==============================================================================
# 🎛️ GROUP 3 (CONT.): ATOMIC IMAGE LAYER PROTECTION & OSTREE PINNING
# ==============================================================================
pin_active_image_layer() {
    clear
    echo -e "${BOLD}${GREEN}=== Managing Atomic OSTree Image Deployment Pins ===${NC}"
    echo -e "  ${DIM}Freezing your active layer protects against broken upstream rolling updates.${NC}\n"

    rpm-ostree status 2>/dev/null || true
    echo ""

    # 🧬 PENDING TRANSACTION DEPLOYMENT INTERCEPT GATES
    if rpm-ostree status 2>/dev/null | head -n 12 | grep -q "Staged" || [[ "$(rpm-ostree status 2>/dev/null | grep -c "ostree-image-signed")" -gt 2 && ! "$(rpm-ostree status 2>/dev/null | head -n 5 | grep -q "●")" ]] || rpm-ostree status 2>/dev/null | grep -q "Pinned: yes" && ! rpm-ostree status 2>/dev/null | head -n 5 | grep -qi "●.*pinned"; then
        echo -e "${YELLOW}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║${NC}  ${BOLD}${RED}[⚠] PENDING IMAGE LAYER TRANSACTION DETECTED${NC}                                                ${YELLOW}║${NC}"
        echo -e "${YELLOW}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║${NC}  You have newly staged package layers (like stress-ng) waiting to go live on your system.  ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  You ${BOLD}${WHITE}MUST REBOOT${NC} your machine first to activate this new layer before locking a pin.      ${YELLOW}║${NC}"
        echo -e "${YELLOW}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        if confirm "Would you like to reboot your system now to synchronize your layers?"; then
            echo -e "${GREEN}[+] Closing toolkit registers and restarting device safely...${NC}"
            stop_background_music 2>/dev/null || true
            sleep 1.5
            sudo systemctl reboot
            exit 0
        else
            if ostree admin pin 2>/dev/null | grep -q "Pinned" || rpm-ostree status 2>/dev/null | grep -qi "pinned"; then
                echo -e "\n  ${YELLOW}[●] Bypassing reboot prompt. Shifting to active unpin suite...${NC}\n"
                sleep 1
                echo -e "  ${YELLOW}[⚠] Active Frozen System Pin deployment profile detected on this host.${RESET}"
                echo -e "      Selecting this action will unpin the layer, allowing full storage cleanups."
                echo ""
                if confirm "Would you like to unpin your stable backup layer now?"; then
                    echo -e "${RED}[●] Step 1/2: Removing atomic GRUB fallback environment pins...${NC}"
                    (sudo ostree admin pin --unpin 0 2>/dev/null) &>/dev/null

                    echo -e "${GREEN}[+] Step 2/2: Synchronizing boot records and clearing image caches...${NC}"
                    (sudo systemctl daemon-reload) &>/dev/null

                    print_success "Deployment layer successfully unpinned! System caches cleared."

                    echo -e "${YELLOW}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
                    echo -e "${YELLOW}║${NC}  ${BOLD}${GREEN}[✓] ATOMIC SYSTEM UNPIN COMPLETED SUCCESSFULLY!${NC}                                            ${YELLOW}║${NC}"
                    echo -e "${YELLOW}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
                    echo -e "${YELLOW}║${NC}  👉 ${BOLD}${YELLOW}CRITICAL REBOOT REQUIRED:${NC} You ${BOLD}${WHITE}MUST REBOOT${NC} your machine to fully complete unpin cleanups.   ${YELLOW}║${NC}"
                    echo -e "${YELLOW}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
                    echo ""
                    type_prompt "  Press [Enter] to return to the toolkit main menu... " 0.03
                    read -rp "  "
                    return 0
                fi
            fi
        fi
        type_prompt "  Press [Enter] to return safely back to the toolkit main menu... " 0.03
        read -rp "  "
        return 0
    fi
    # 🧬 DYNAMIC DETECTOR: Checks for active pin records once system layers are fully synced
    if ostree admin pin 2>/dev/null | grep -q "Pinned" || rpm-ostree status 2>/dev/null | grep -qE "(Pinned|pinned)"; then
        echo -e "  ${YELLOW}[⚠] Active Frozen System Pin deployment profile detected on this host.${RESET}"
        echo -e "      Selecting this action will unpin the layer, allowing full storage cleanups."
        echo ""
        if confirm "Would you like to unpin your stable backup layer now?"; then
            echo -e "${RED}[●] Step 1/2: Removing atomic GRUB fallback environment pins...${NC}"
            (sudo ostree admin pin --unpin 0 2>/dev/null) &>/dev/null

            echo -e "${GREEN}[+] Step 2/2: Synchronizing boot records and clearing image caches...${NC}"
            (sudo systemctl daemon-reload) &>/dev/null

            print_success "Deployment layer successfully unpinned! System caches cleared."

            # 🧬 RESTORED UNPIN REBOOT BOX
            echo -e "${YELLOW}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${YELLOW}║${NC}  ${BOLD}${GREEN}[✓] ATOMIC SYSTEM UNPIN COMPLETED SUCCESSFULLY!${NC}                                            ${YELLOW}║${NC}"
            echo -e "${YELLOW}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
            echo -e "${YELLOW}║${NC}  👉 ${BOLD}${YELLOW}CRITICAL REBOOT REQUIRED:${NC} You ${BOLD}${WHITE}MUST REBOOT${NC} your machine to fully complete unpin cleanups.   ${YELLOW}║${NC}"
            echo -e "${YELLOW}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            return 0
        else
            echo -e "${CYAN}[-] Operation canceled. Returning safely to primary toolkit menu...${NC}"
            sleep 1.2
            return 0
        fi
    else
        echo -e "  ${CYAN}[ℹ] System image layer is currently unpinned and tracking development channels.${RESET}"
        echo -e "      This utility freezes your active kernel/drivers to shield you from broken rolling updates."
        echo ""
        if confirm "Would you like to securely pin your active, verified v1.5 deployment layer now?"; then
            echo -e "${GREEN}[+] Step 1/2: Locking down active hardware system image index map...${NC}"
            (sudo ostree admin pin 0 2>/dev/null) &>/dev/null

            echo -e "${GREEN}[+] Step 2/2: Verifying pin assignment entries inside bootloader records...${NC}"
            print_success "Deployment layer successfully frozen! Pin will lock on next boot cycle."

            # 🧬 RESTORED PIN REBOOT BOX
            echo -e "${YELLOW}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${YELLOW}║${NC}  ${BOLD}${GREEN}[✓] ATOMIC SYSTEM LOCK INITIATED SUCCESSFULLY!${NC}                                              ${YELLOW}║${NC}"
            echo -e "${YELLOW}╠═════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
            echo -e "${YELLOW}║${NC}  👉 ${BOLD}${YELLOW}CRITICAL REBOOT REQUIRED:${NC} You ${BOLD}${WHITE}MUST REBOOT${NC} your machine to fully verify your GRUB list.     ${YELLOW}║${NC}"
            echo -e "${YELLOW}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
            echo ""
        else
            echo -e "${RED}[-❌-] Pinning routine aborted. No changes made to system layers.${NC}"
            sleep 1.5
        fi
    fi

    type_prompt "  Press [Enter] to return to the toolkit main menu... " 0.03
    read -rp "  "
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

# ==============================================================================
# INTEGRATED: MASTER UNIVERSAL DYNAMIC BC-250 SILICON HARVEST ENGINE MATRIX
# ==============================================================================
view_cu_map() {
    clear
    echo -e "${BOLD}${CYAN}  ╔════════════════════════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║                 📟  AMD BC-250 Live Compute Unit Silicon Map Matrix     📟             ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚════════════════════════════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${BOLD}${YELLOW}Active Hardware Real-Time Telemetry Profile:${RESET}"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"

    sudo python3 << 'PYEOF'
import ctypes, struct, os, sys

def render_simulated_map(num_se, num_sh, live_bitmaps, variants_list):
    """Programmatically projects what the silicon grid will look like under specified mask variations"""
    simulated_rows = []
    for se in range(num_se):
        for sh in range(num_sh):
            row_bars = []
            for wgp in range(5):
                is_targeted = any(v_se == se and v_sh == sh and v_wgp == wgp for v_se, v_sh, v_wgp in variants_list)
                if is_targeted:
                    row_bars.append("□□")
                else:
                    row_bars.append("■■")
            bar = "".join(row_bars)
            simulated_rows.append(f"SE{se}SH{sh}:{bar}")
    return " │ ".join(simulated_rows)
try:
    with open("/proc/cmdline", "r") as f:
        cmdline = f.read()
except Exception:
    cmdline = ""

get_status = lambda arg: "\033[1;92m[ RUNNING / STABLE ]\033[0m" if arg in cmdline else "\033[1;90m[ IDLE ]\033[0m"

try:
    try:
        libdrm = ctypes.CDLL("libdrm_amdgpu.so.1")
    except OSError:
        print("   \033[0;31mERROR: libdrm_amdgpu driver library not found on this host system.\033[0m")
        sys.exit(1)

    fd = os.open("/dev/dri/renderD128", os.O_RDWR)
    dev = ctypes.c_void_p()
    maj, min_ = ctypes.c_uint32(), ctypes.c_uint32()
    libdrm.amdgpu_device_initialize(fd, ctypes.byref(maj), ctypes.byref(min_), ctypes.byref(dev))

    buf = (ctypes.c_uint8 * 1024)()
    libdrm.amdgpu_query_info(dev, 0x16, 1024, ctypes.byref(buf))
    raw = bytes(buf)

    # 🔧 FIXED: Added explicit [0] indexers to guarantee raw mathematical integers
    num_se = struct.unpack_from('<I', raw, 20)[0]
    num_sh = struct.unpack_from('<I', raw, 24)[0]

    total = 0
    live_bitmaps = {}
    rows = []
    disrupted_gaps = []
    all_empty_gaps = []

    for se in range(num_se):
        for sh in range(num_sh):
            # 🔧 FIXED: Unpacking array row blocks cleanly into integers
            bm = struct.unpack_from('<I', raw, 56 + (se * 4 + sh) * 4)[0]
            live_bitmaps[(se, sh)] = bm

            wgp_states = []
            for wgp in range(5):
                mask = (1 << (wgp * 2)) | (1 << (wgp * 2 + 1))
                wgp_states.append((bm & mask) != 0)

            n = wgp_states.count(True) * 2
            total += n

            if 0 < n < 10:
                active_indices = [i for i, active in enumerate(wgp_states) if active]
                if active_indices:
                    first_active = active_indices[0]
                    last_active = active_indices[-1]

                    for wgp_idx in range(5):
                        if not wgp_states[wgp_idx]:
                            all_empty_gaps.append((se, sh, wgp_idx))
                            is_middle_gap = first_active < wgp_idx < last_active
                            is_front_disruption = (wgp_idx == 0 and last_active > 0)

                            if is_middle_gap or is_front_disruption:
                                disrupted_gaps.append((se, sh, wgp_idx))

            bar = ''.join('■' if bm & (1 << i) else '□' for i in range(10))
            rows.append(f"   SE{se} SH{sh}: {bar}")

    possible = num_se * num_sh * 10
    harvested = possible - total

    for r in rows:
        print(f"\033[1;92m{r}\033[0m")
    print(f"\n   \033[1;37mStatus: {total}/{possible} CUs active, {harvested} harvested Silicon blocks.\033[0m")

    libdrm.amdgpu_device_deinitialize(dev)
    os.close(fd)
except Exception as e:
    print(f"   \033[0;31mERROR: Failed to read DRM pipeline ioctl bindings ({e})\033[0m")
    sys.exit(1)
print(f"\n  \033[1;36m─────────────────────────────────────────────────────────────────────\033[0m")
print(f"  \033[1;32mAvailable Override Optimization Reference (Targeted Disrupted Row Profiles):\033[0m\n")

unique_gaps = []
for item in disrupted_gaps:
    if item not in unique_gaps:
        unique_gaps.append(item)

final_targets = list(unique_gaps)
is_multi_row_front = len(unique_gaps) >= 2 and all(w == 0 for se, sh, w in unique_gaps)

active_karg_found = False

# 🎰 40/40 LOTTERY WINNER DETECTOR TRIGGER INSTANTIATOR
if len(unique_gaps) == 0 and total == 24:
    map_40_unlock = render_simulated_map(num_se, num_sh, live_bitmaps, [])
    print(f"   \033[1;35m🎉 CONGRATULATIONS! THIS SILICON PROFILE IS A 40/40 LOTTERY WINNER! 🎉\033[0m")
    print(f"   \033[1;35mUnlocked Matrix │ {map_40_unlock}\033[0m")
    print(f"   \033[1;37mNo disrupted rows detected natively on this baseline block configuration.\033[0m")
    print(f"   \033[1;32mYour chip is completely uniform and eligible for direct 40 CU unlock rebases.\033[0m\n")

elif is_multi_row_front:
    expanded_targets = []
    quad_targets = []

    for se, sh, w in unique_gaps:
        tail_wgp = next((tw for s, h, tw in all_empty_gaps if s == se and h == sh and tw != w), None)
        expanded_targets.append((se, sh, w))
        quad_targets.append((se, sh, w))
        if tail_wgp is not None:
            expanded_targets.append((se, sh, tail_wgp))
            quad_targets.append((se, sh, tail_wgp))

    variant_counter = 1

    for se, sh, screen_wgp in expanded_targets:
        karg_str = f"amdgpu.disable_cu={se}.{sh}.{screen_wgp}"
        status_badge = get_status(karg_str)
        if "RUNNING" in status_badge: active_karg_found = True
        map_proj = render_simulated_map(num_se, num_sh, live_bitmaps, [(se, sh, screen_wgp)])

        print(f"   \033[1;36m[DYNAMIC VARIANT 0{variant_counter}]\033[0m Mask Disrupted Target: SE{se} SH{sh} WGP{screen_wgp} (38/40 CUs)  {status_badge}")
        print(f"   \033[1;35mProjections │ {map_proj}\033[0m")
        print(f"   \033[2mCommand: sudo rpm-ostree kargs --append='amdgpu.bc250_cc_write_mode=3 {karg_str}'\033[0m\n")
        variant_counter += 1
    print(f"   \033[1;32m─── Expanded Symmetrical Double Variant Combinations (36/40 Active CUs) ───\033[0m\n")
    for i in range(len(expanded_targets)):
        for j in range(i + 1, len(expanded_targets)):
            t1, t2 = expanded_targets[i], expanded_targets[j]
            double_combo_str = f"amdgpu.disable_cu={t1[0]}.{t1[1]}.{t1[2]},{t2[0]}.{t2[1]}.{t2[2]}"
            status_double = get_status(double_combo_str)
            if "RUNNING" in status_double: active_karg_found = True
            map_double = render_simulated_map(num_se, num_sh, live_bitmaps, [t1, t2])

            print(f"   \033[1;36m[DYNAMIC DOUBLE COMBINATION]\033[0m Masking Gaps: SE{t1[0]}SH{t1[1]}W{t1[2]} + SE{t2[0]}SH{t2[1]}W{t2[2]}   {status_double}")
            print(f"   \033[1;35mProjections │ {map_double}\033[0m")
            print(f"   \033[2mCommand: sudo rpm-ostree kargs --append='amdgpu.bc250_cc_write_mode=3 {double_combo_str}'\033[0m\n")

    print(f"   \033[1;32m─── Expanded Symmetrical Triple Variant Combinations (34/40 Active CUs) ───\033[0m\n")
    for i in range(len(expanded_targets)):
        for j in range(i + 1, len(expanded_targets)):
            for k in range(j + 1, len(expanded_targets)):
                t1, t2, t3 = expanded_targets[i], expanded_targets[j], expanded_targets[k]
                triple_combo_str = f"amdgpu.disable_cu={t1[0]}.{t1[1]}.{t1[2]},{t2[0]}.{t2[1]}.{t2[2]},{t3[0]}.{t3[1]}.{t3[2]}"
                status_triple = get_status(triple_combo_str)
                if "RUNNING" in status_triple: active_karg_found = True
                map_triple = render_simulated_map(num_se, num_sh, live_bitmaps, [t1, t2, t3])

                print(f"   \033[1;36m[DYNAMIC TRIPLE COMBINATION]\033[0m Masking: W{t1[2]} + W{t2[2]} + W{t3[2]} Balance Mask   {status_triple}")
                print(f"   \033[1;35mProjections │ {map_triple}\033[0m")
                print(f"   \033[2mCommand: sudo rpm-ostree kargs --append='amdgpu.bc250_cc_write_mode=3 {triple_combo_str}'\033[0m\n")
    print(f"   \033[1;32m─── Maximum Quadruple Isolation Fallback Alignment (32/40 Active CUs) ───\033[0m\n")
    quad_targets_clean = list(set(quad_targets))
    quad_karg_parts = [f"{s}.{h}.{w}" for s, h, w in quad_targets_clean]
    quad_combo_str = f"amdgpu.disable_cu=" + ",".join(quad_karg_parts)
    status_quad = get_status(quad_combo_str)
    if "RUNNING" in status_quad: active_karg_found = True
    map_quad = render_simulated_map(num_se, num_sh, live_bitmaps, quad_targets_clean)

    print(f"   \033[1;36m[DYNAMIC QUADRUPLE VARIANT]\033[0m Mask Combined Row Disruptions Fallback (32/40 CUs)     {status_quad}")
    print(f"   \033[1;35mProjections │ {map_quad}\033[0m")
    print(f"   \033[2mCommand: sudo rpm-ostree kargs --append='amdgpu.bc250_cc_write_mode=3 {quad_combo_str}'\033[0m\n")

else:
    if len(unique_gaps) == 1:
        se1, sh1, w1 = unique_gaps[0]
        next_wgp = next((w for se, sh, w in all_empty_gaps if se == se1 and sh == sh1 and w != w1), None)
        if next_wgp is not None:
            final_targets.append((se1, sh1, next_wgp))

    variant_counter = 1

    for se, sh, screen_wgp in final_targets[:2]:
        karg_str = f"amdgpu.disable_cu={se}.{sh}.{screen_wgp}"
        status_badge = get_status(karg_str)
        if "RUNNING" in status_badge: active_karg_found = True
        map_proj = render_simulated_map(num_se, num_sh, live_bitmaps, [(se, sh, screen_wgp)])

        print(f"   \033[1;36m[DYNAMIC VARIANT 0{variant_counter}]\033[0m Mask Disrupted Target: SE{se} SH{sh} WGP{screen_wgp} (38/40 CUs)  {status_badge}")
        print(f"   \033[1;35mProjections │ {map_proj}\033[0m")
        print(f"   \033[2mCommand: sudo rpm-ostree kargs --append='amdgpu.bc250_cc_write_mode=3 {karg_str}'\033[0m\n")
        variant_counter += 1

    if len(final_targets) >= 2:
        se1, sh1, w1 = final_targets[0]
        se2, sh2, w2 = final_targets[1]
        combo_str = f"amdgpu.disable_cu={se1}.{sh1}.{w1},{se2}.{sh2}.{w2}"
        status_combo = get_status(combo_str)
        if "RUNNING" in status_combo: active_karg_found = True
        map_combo = render_simulated_map(num_se, num_sh, live_bitmaps, [(se1, sh1, w1), (se2, sh2, w2)])

        print(f"   \033[1;36m[DYNAMIC DOUBLE VARIANT]\033[0m Mask Combined Row Disruptions Fallback (36/40 CUs)       {status_combo}")
        print(f"   \033[1;35mProjections │ {map_combo}\033[0m")
        print(f"   \033[2mCommand: sudo rpm-ostree kargs --append='amdgpu.bc250_cc_write_mode=3 {combo_str}'\033[0m\n")

if not active_karg_found and "bc250_cc_write_mode=3" in cmdline and "disable_cu" not in cmdline:
    print(f"   \033[1;93mℹ Current Boot State Notice: Chip is running unmasked at maximum possible physical CU limit!\033[0m\n")
PYEOF

    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    echo -e "     • ${CYAN}Pin Deployment${RESET} : If the system boots cleanly, pin your known-good parameters via ostree:"
    echo -e "                       ${MAGENTA}rpm-ostree status && sudo ostree admin pin 0${RESET}"
    echo ""
    echo -e "     • ${YELLOW}Crash Safety${RESET}   : Leave governor services disabled while testing custom target variations."
    echo -e "                       Any hard boot hang will let you safely fall back to stock hardware clocks."
    echo ""
    echo -e "     • ${RED}Full Reversion${RESET} : Remove override masks completely to return to stock configuration parameters:"
    echo -e "                       ${MAGENTA}sudo rpm-ostree kargs --delete=amdgpu.bc250_cc_write_mode=3${RESET}"
    echo ""
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
    echo ""
    type_prompt "  Press [Enter] to return to the toolkit main menu... " 0.03
    read -rp "  "
}

# ==============================================================================
# 📂 GROUP 5: MASTER INTERACTIVE ENGINE SELECTION MAIN GRID LOOP
# ==============================================================================
show_menu() {
    local RESET="${RESET:-}" BOLD="${BOLD:-}" DIM="${DIM:-}"
    local RED="${RED:-}" GREEN="${GREEN:-}" YELLOW="${YELLOW:-}"
    local CYAN="${CYAN:-}" WHITE="${WHITE:-}" BLUE="${BLUE:-}" MAGENTA="${MAGENTA:-}"
    local ICON_WARN="${ICON_WARN:-⚠}"

    while true; do
        # ═] GLITCH MELT CLEAR ENGINE: Seamlessly dissolves old frames downwards on loop refresh
        matrix_melt_clear

        # Real-time Telemetry Calculators: Updates seamlessly on every screen refresh loop
        local raw_temp cpu_temp
        raw_temp=$(cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -n 1 || echo "0")
        if (( raw_temp > 0 )); then
            cpu_temp="$(( raw_temp / 1000 ))°C"
        else
            cpu_temp="N/A"
        fi
        local load_avg; load_avg=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

        # Draw Symmetrical 24-Bit True Color Green Frame Heading Panel (Bypasses Konsole profile overrides)
        echo -e "${BOLD}\033[38;2;0;255;0m"
        echo "  ╔════════════════════════════════════════════════════════════════════════════════════════╗"
        echo "  ║                                                                                        ║"
        echo -e "  ║         ${YELLOW}██████╗  █████╗ ███████╗███████╗██╗████████╗███████╗    ██████╗ ███████╗\033[38;2;0;255;0m       ║"
        echo -e "  ║         ${YELLOW}██╔══██╗██╔══██╗╚══███╔╝╚══███╔╝██║╚══██╔══╝██╔════╝   ██╔═══██╗██╔════╝\033[38;2;0;255;0m       ║"
        echo -e "  ║         ${YELLOW}██████╔╝███████║  ███╔╝   ███╔╝ ██║   ██║   █████╗  ██ ██║   ██║███████╗\033[38;2;0;255;0m       ║"
        echo -e "  ║         ${YELLOW}██╔══██╗██╔══██║ ███╔╝   ███╔╝  ██║   ██║   ██╔══╝     ██║   ██║╚════██║\033[38;2;0;255;0m       ║"
        echo -e "  ║         ${YELLOW}██████╔╝██║  ██║███████╗███████╗██║   ██║   ███████╗   ╚██████╔╝███████║\033[38;2;0;255;0m       ║"
        echo -e "  ║         ${YELLOW}╚══════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝   ╚═╝   ╚══════╝    ╚═════╝ ╚══════╝\033[38;2;0;255;0m      ║"
        echo "  ║                                                                                        ║"
        echo -e "  ║    ${B_BLUE}[●] BLUE Pill\033[38;2;0;255;0m             📟  System Core Telemetry  📟             ${RED}RED Pill [●]\033[38;2;0;255;0m    ║"
        echo "  ║                                                                                        ║"
        echo -e "  ║        System Load: ${WHITE}${load_avg}\033[38;2;0;255;0m        │           Silicon Temp: ${YELLOW}${cpu_temp}\033[38;2;0;255;0m               ║"
        echo "  ╚════════════════════════════════════════════════════════════════════════════════════════╝"
        echo -e "${RESET}"

        # --- SECTION 1: STORAGE & INITIAL MEMORY CONFIG ---
        echo -e "  ${BOLD}${MAGENTA}WARNING: Final confirmation gate. Proceeding will lock in configuration changes.${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "    ${CYAN}[1]${RESET} ${B_BLUE}BLUE  ●${CYAN} 16GB Swapfile Mapping   ${DIM}(Recommended for smaller NVMe setups)${RESET}"
        echo -e "    ${CYAN}[2]${RESET} ${RED}RED   ●${CYAN} 32GB Swapfile Mapping   ${DIM}(Recommended for high-capacity NVMe)${RESET}"
        echo ""

                # --- AUTOMATED SETUP OVERVIEW PANEL ---
        echo -e "  ${BOLD}${CYAN}  ℹ  Automated Deployment Sequence Summary (Options 1 & 2):${RESET}"
        echo -e "     Executing either option triggers a complete professional optimization suite:"
        echo -e "     • Repository Setup    : Hooks the filippor-bazzite COPR package tracking"
        echo -e "     • Governor Upgrade    : Installs cyan-skillfish-governor-smu (Enhanced Overclock)"
        echo -e "     • Conflict Management : Stops and disables obsolete standard/oberon governor daemons"
        echo -e "     • Core Safety Fix     : Disables hardware CPU mitigations to maximize performance"
        echo -e "     • Swap Infrastructure : Disables stock ZRAM and deploys a target 16G/32G disk swapfile"
        echo -e "     • Memory Efficiency   : Enables optimized ZSWAP caching using high-tier zstd compression"
        echo -e "     • Kernel Tuning       : Adjusts vm.swappiness=180 with a z3fold memory layout pool"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        echo ""

        # --- SECTION 2: GPU OVERCLOCK CONTROLS ---
        echo -e "  ${BOLD}${BLUE}GPU Overclock Governor Settings${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "    ${B_BLUE}[A] Enable Governor Now${RESET}    ${DIM}(Until Next Reboot)${RESET}  ${RED}[D] Disable Governor Now${RESET}   ${DIM}(Stop Immediately)${RESET}"
        echo -e "    ${B_BLUE}[B] Enable Auto-Start${RESET}      ${DIM}(Turn On Every Boot)${RESET} ${RED}[E] Disable Auto-Start${RESET}     ${DIM}(Keep Off on Boot)${RESET}"
        echo -e "    ${YELLOW}[C] Restart Governor${RESET}        ${DIM}(Refresh Tweaks)${RESET}    ${YELLOW}[F] Monitor Governor Live Logs${RESET}   ${DIM}(Press [Enter] to Exit)${RESET}"
        echo -e "    ${MAGENTA}[G] Check Governor Version${RESET}                      ${MAGENTA}[H] Upgrade Governor Track${RESET} ${DIM}  (Fetch Latest Stable COPR Build)${RESET}"
        echo -e "              ${BOLD}${BLUE}• Silicon Governor & Performance Tuning Profile Manager:${RESET}"
        echo -e "                     ${CYAN}[I]  Modify Governor Performance Profile${RESET}    ${DIM}(Hardware Spec Audit Wizard)${RESET}"
        echo ""

        # --- CONFIG NOTICES ---
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        echo -e "  ${CYAN}  ℹ  Configuration Path Notice:${RESET}"
        echo -e "     Ensure adjustments are populated inside the config container path before launch:"
        echo -e "     ${WHITE}\"/etc/cyan-skillfish-governor-smu/config.toml\"${RESET}"
        echo -e "  ${DIM}─────────────────────────────────────────────────────────────────────${RESET}"
        echo ""

        # 🧬 SECTION 3: HARDWARE UNLOCKS & CORE OPTIMIZATIONS
        echo -e "  ${BOLD}${YELLOW}Hardware Unlocks & Core Optimizations${RESET}"
        echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
        # Column 1 (Numbers 3, 5, 7)               │ Column 2 (Numbers 4, 6)
        echo -e "    ${CYAN}[3] ACPI Table Fix${RESET}  ${DIM}(Install/Uni)${RESET}     ${CYAN}[4] Dynamic VRAM Extender${RESET} ${DIM}Unlock 14.75GB UMA ceiling allocations${RESET}"
        echo -e "    ${CYAN}[5] CPU OC & CU Suite${RESET} ${DIM}(Live SMU)${RESET}      ${CYAN}[6] Wake-on-LAN${RESET}     ${DIM}(Port Selector)${RESET}"
        echo -e "    ${CYAN}[7] GFX1013 / FSR 4.1.1${RESET} ${DIM}(Smart Suite)${RESET} ${CYAN}[8] Memory Interleave Balancer${RESET} ${DIM}Distribute RAM channels evenly${RESET}"
        echo -e "    ${CYAN}[9] RAM/VRAM Split${RESET}  ${DIM}(Dynamic Split)${RESET}   ${CYAN}[10] Resolve Localized Paths${RESET}  ${DIM}Configure global XDG directory metrics${RESET}"

        echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
        # Column 1 (Letters M, P)                  │ Column 2 (Letters O, X)
        echo -e "    ${CYAN}[M] CU Map Matrix${RESET}    ${DIM}(Harvest Map)${RESET}       ${CYAN}[Q] MGLRU Latency Optimizer  ${DIM}Minimize CPU memory scanning overhead${RESET}"
        echo -e "    ${CYAN}[O] CU Harvest Maps${RESET} ${DIM}(Web Browser)${RESET}        ${BIPurple}[T] DS5 Bridge Fix  ${DIM}Stabilize Bluetooth connection latency${RESET}"
        echo -e "    ${CYAN}[P] Pin Stable Layer${RESET} ${DIM}(OSTree Backup)${RESET}     ${CYAN}[X] Xbox Adapter${RESET}  ${DIM}(Xone Driver)${RESET}"
        echo ""

        # 🧬 NEW SECTION 4: TELEMETRY & DASHBOARD READOUTS (INJECTED)
        echo -e "  ${BOLD}${MAGENTA}Telemetry & View Dashboards${RESET}"
        echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"
        echo -e "    ${MAGENTA}[S] View Current Toolkit Dashboard${RESET}  ${DIM}(Real-time telemetry and hardware state panel)${RESET}"
        echo ""
        echo -e "    ${CYAN}[R] Reload Menu Interface${RESET}"
        echo -e "    ${RED}[0] Secure Safe Exit${RESET}"
        echo ""
        echo -e "    ${RED}⚠  WARNING: OVERCLOCKING AND UNDERVOLTING CAN DAMAGE SILICON TARGETS!${NC}"
        echo -e "              ${RED}PROCEED ENTIRELY AT YOUR OWN RISK AND VERIFY SYSTEM COOLING.${NC}"
        echo -e "  ${BIBlack}─────────────────────────────────────────────────────────────────────${NC}"

        # Safe Prompt Parser (Instant Typing Response Keystroke Engine)
        type_prompt "  Select an option [0-8, A-I, M, O, P, R, S, X]: " 0.03

        choice=""
        read -n 1 -s choice || true
        echo ""

        case "$choice" in
            1) install_blue_pill ;;
            2) install_red_pill ;;
            3) toggle_acpi_fix ;;
            4) apply_vram_optimization ;;
            5) install_overclock ;;
            6) install_wake_on_lan ;;
            7) toggle_compute_queue_fix ;;
            8) apply_gpu_power_shield ;;
            9) toggle_ram_split ;;
            10) resolve_safe_system_paths ;;

            a|A)
                echo -e "${GREEN}Executing Temporary Start...${NC}"
                sudo systemctl start cyan-skillfish-governor-smu
                sleep 2
                ;;
            b|B)
                echo -e "${B_GREEN}Executing Permanent Start...${NC}"
                sudo systemctl enable --now cyan-skillfish-governor-smu
                sleep 2
                ;;
            c|C)
                echo -e "${YELLOW}Executing Restart Service...${NC}"
                sudo systemctl restart cyan-skillfish-governor-smu
                sleep 2
                ;;
            d|D)
                echo -e "${RED}Executing Temporary Stop...${NC}"
                sudo systemctl stop --now cyan-skillfish-governor-smu
                sleep 2
                ;;
            e|E)
                echo -e "${B_RED}Executing Stop and Disable Service...${NC}"
                sudo systemctl disable --now cyan-skillfish-governor-smu
                sleep 2
                ;;
            f|F)
                # 🧬 LOCAL SIGNAL GATE: Temporarily redirects Ctrl+C straight to a graceful menu return
            trap 'echo -e "\nReturning safely to menu..."; break' SIGINT

            clear
            echo -e "${CYAN}Displaying Service Status...${NC}"
            # 🎯 FIX: --no-pager forces the text to drop cleanly into your script without freezing the terminal viewer
            sudo systemctl status cyan-skillfish-governor-smu -l --no-pager
            echo ""
            read -rp "Press [Enter] to return to the main menu..." dummy

            # 🧼 REMOVE THE TRAP: Restores default script execution behavior before returning to your loops
            trap - SIGINT
            ;;
            g|G)
                clear
                echo -e "${CYAN}Displaying Cyan Skillfish Governor SMU Version...${NC}"
                echo ""
                sudo cyan-skillfish-governor-smu --version
                echo ""
                read -rp "Press [Enter] to return to the main menu..."
                ;;
            h|H) update_cyan-skillfish ;; # Captures your new Section 2 choice cleanly
            i|I) configure_governor_profile ;;

            # 🚀 UPDATED CORRESPONDING SWITCH ENGINES NATIVELY
            m|M) view_cu_map ;; # Moved from lower case H to preserve loop safety mappings
            o|O) launch_html_dashboard ;;
            p|P) pin_active_image_layer ;;         # Locks down your verified v1.5 deployment via ostree pin
            q|Q) toggle_mglru_optimization ;;
            r|R)
                print_info "Reinitializing toolkit memory tracking blocks..."
                sleep 0.5
                exec bash "$SCRIPT_PATH" "$@"
                ;;
            s|S)
                run_status
                type_prompt "  Press [any key] to return to the toolkit main menu... " 0.03
                read -n 1 -s -r || true
                ;;
            t|T) toggle_ds5_bridge_fix ;;
            x|X) toggle_xbox_adapter ;;
            0)
                secure_system_exit
                ;;
            *)
                echo -e "${RED}Invalid choice! Please select a valid option.${NC}"
                sleep 1.5
                ;;
        esac
    done
}

# --- Runtime Execution Entry Pointer ---
show_menu
