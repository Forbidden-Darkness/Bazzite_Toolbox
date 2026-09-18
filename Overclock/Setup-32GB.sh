#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
#  Setup-32GB (Bazzite) – NexGen3D v2.0 (RED Pill Profile)
# ────────────────────────────────────────────────────────────────

YELLOW='\033[1;33m' local B_BLUE='\033[1;34m' local RED='\033[0;31m'
DIM='\033[38;2;110;110;110m' local NC='\033[0m' local GREEN='\033[0;32m'
B_GREEN='\033[1;32m' local MAGENTA="\033[1;95m" local BOLD='\033[1m'
local CYAN='\033[0;36m' local B_RED='\033[1;31m' local RESET='\033[0m'

echo ""
echo -e "  ${RED}RED Pill Suite Active Deployment Profile${RESET} │ ${CYAN}Version:${RESET} ${GREEN}v2.0${RESET} [●]"
echo -e "  ${YELLOW}[●] NOTICE: This deployment process takes approximately 25 minutes from start to finish.${NC}"
echo -e "      ${DIM}Please hold steady and let the background transaction compiler finish completely.${NC}"
echo ""

echo "[●] Step 1/8: Stopping obsolete governor daemon services..."
(systemctl disable --now cyan-skillfish-governor 2>/dev/null || true) &>/dev/null
(systemctl disable --now cyan-skillfish-governor-tt 2>/dev/null || true) &>/dev/null
(systemctl disable --now oberon-governor 2>/dev/null || true) &>/dev/null

echo "[●] Step 2/8: Enabling the filippor/bazzite COPR repository..."
(sudo copr enable filippor/bazzite -y 2>/dev/null || true) &>/dev/null

echo "[●] Step 3/8: Cleaning and refreshing rpm-ostree metadata tracking..."
(sudo rpm-ostree cleanup -m 2>/dev/null || true) &>/dev/null
(sudo rpm-ostree refresh-md 2>/dev/null || true) &>/dev/null

echo "[●] Step 4/8: Staging Enhanced Cyan Skillfish Governor SMU layers..."
is_reinstall=false
if [[ -d /usr/etc/cyan-skillfish-governor-smu || -f /var/log/bc250_oc_install.log ]]; then
    is_reinstall=true
fi

(sudo rpm-ostree cleanup -p 2>/dev/null || true) &>/dev/null
(rpm-ostree install -y cyan-skillfish-governor-smu 2>/dev/null || true) &>/dev/null

if [ "$is_reinstall" = true ]; then
    (sudo bash -c 'cat << "EOF" > /etc/systemd/system/gln-reinstall-sync.service
[Unit]
Description=Post-Reboot Governor Directory Self-Healing Sync
Before=cyan-skillfish-governor-smu.service
ConditionPathExists=!/etc/cyan-skillfish-governor-smu/config.toml
[Service]
Type=oneshot
ExecStart=/usr/bin/mkdir -p /etc/cyan-skillfish-governor-smu
ExecStart=/usr/bin/cp -n /usr/etc/cyan-skillfish-governor-smu/config.toml /etc/cyan-skillfish-governor-smu/config.toml
ExecStart=/usr/bin/systemctl disable gln-reinstall-sync.service
ExecStart=/usr/bin/rm -f /etc/systemd/system/gln-reinstall-sync.service
[Install]
WantedBy=multi-user.target
EOF' 2>/dev/null || true) &>/dev/null
    (sudo systemctl daemon-reload 2>/dev/null || true) &>/dev/null
    (sudo systemctl enable gln-reinstall-sync.service 2>/dev/null || true) &>/dev/null
fi

echo "[●] Step 5/8: Injecting optimized performance flags into atomic kernel args (kargs)..."
(rpm-ostree kargs --delete=systemd.zram=1 2>/dev/null || true) &>/dev/null
(rpm-ostree kargs --delete=zram.num_devices=1 2>/dev/null || true) &>/dev/null
(rpm-ostree kargs --delete=zswap.max_pool_percent=25 2>/dev/null || true) &>/dev/null
(rpm-ostree kargs --delete=zswap.compressor=lz4 2>/dev/null || true) &>/dev/null

# 🚀 THE ZSWAP EXTREME PERFORMANCE PACK: Hardlocks zstd compression and z3fold triple-packing schemes active
(rpm-ostree kargs --append-if-missing=mitigations=off 2>/dev/null || true) &>/dev/null
(rpm-ostree kargs --append-if-missing=zswap.enabled=1 2>/dev/null || true) &>/dev/null
(rpm-ostree kargs --append-if-missing=zswap.compressor=zstd 2>/dev/null || true) &>/dev/null
(rpm-ostree kargs --append-if-missing=zswap.zpool=z3fold 2>/dev/null || true) &>/dev/null
(rpm-ostree kargs --append-if-missing=zswap.max_pool_percent=40 2>/dev/null || true) &>/dev/null
(rpm-ostree kargs --append-if-missing=systemd.zram=0 2>/dev/null || true) &>/dev/null

echo "[●] Step 6/8: Purging fragmented system layers and allocating unfragmented 32GB storage swap..."
(sudo swapoff /var/swap/swapfile 2>/dev/null || true) &>/dev/null
(sudo rm -f /var/swap/swapfile 2>/dev/null || true) &>/dev/null
(sudo btrfs subvolume delete /var/swap 2>/dev/null || true) &>/dev/null
(sudo btrfs subvolume create /var/swap 2>/dev/null || true) &>/dev/null
(sudo semanage fcontext -a -t var_t /var/swap 2>/dev/null || true) &>/dev/null
(sudo restorecon /var/swap 2>/dev/null || true) &>/dev/null
(sudo btrfs filesystem mkswapfile --size 32G /var/swap/swapfile 2>/dev/null || true) &>/dev/null
(sudo semanage fcontext -a -t swapfile_t /var/swap/swapfile 2>/dev/null || true) &>/dev/null
(sudo restorecon /var/swap/swapfile 2>/dev/null || true) &>/dev/null

echo "[●] Step 7/8: Finalizing persistent fstab maps and tuning virtual memory (swappiness=100)..."
(sudo sed -i '/\/var\/swap\/swapfile/d' /etc/fstab) &>/dev/null
(sudo rm -f /etc/systemd/zram-generator.conf 2>/dev/null || true) &>/dev/null
(sudo bash -c 'echo /var/swap/swapfile none swap defaults,nofail 0 0 >> /etc/fstab') &>/dev/null
(sudo tee /etc/sysctl.d/99-swappiness.conf <<< "vm.swappiness = 100" 2>/dev/null || true) &>/dev/null

echo "[●] Step 8/8: Compiling zstd acceleration drivers within system initramfs maps..."
(rpm-ostree initramfs --enable --arg=--add-drivers --arg=zstd 2>/dev/null || true) &>/dev/null

echo ""
echo -e "${B_GREEN}Setup Complete${NC}"
echo -e "Please reboot your system using the following command: ${B_BLUE}systemctl reboot${NC}"
echo ""

echo -e "\033[5m${B_RED}╔═════════════════════════════════════════════════════════════════════════════════════════════╗${RESET}"
echo -e "\033[5m${B_RED}║  [⚠] CRITICAL POST-REBOOT CONFIGURATION REQUIRED                                            ║${RESET}"
echo -e "\033[5m${B_RED}╚═════════════════════════════════════════════════════════════════════════════════════════════╝${RESET}"
echo -e "    ${BOLD}${B_GREEN}● STEP 1:${NC} Do ${BOLD}${RED}NOT${NC} activate the Governor immediately upon rebooting."
echo -e "    ${BOLD}${B_GREEN}● STEP 2:${NC} You ${BOLD}${YELLOW}MUST${NC} customize your hardware profiles to prevent instability targets."
echo -e "    ${BOLD}${B_GREEN}● STEP 3:${NC} Open and modify your custom parameters using a text editor at this path:"
echo -e "              👉  ${BOLD}${MAGENTA}/etc/cyan-skillfish-governor-smu/config.toml${NC}"
echo -e "    ${BOLD}${B_GREEN}● STEP 4:${NC} Save your profile adjustments first, then turn the governor service ${B_GREEN}ON${NC}."
echo ""
echo "After the system has rebooted, if you wish to test GPU overclocking, then run the following command in the terminal: systemctl start cyan-skillfish-governor-smu"
echo -e "${RED}CAUTION -> Overclocking the GPU can cause increased system heat and system instability${NC}"
echo ""
