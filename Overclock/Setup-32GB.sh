#!/usr/bin/env bash
# ────────────────────────────────────────────────────────────────
#  Setup-32GB (Bazzite) – NexGen3D v2.0 (RED Pill Profile)
# ────────────────────────────────────────────────────────────────
YELLOW='\033[1;33m' B_BLUE='\033[1;34m' RED='\033[0;31m'
DIM='\033[38;2;110;110;110m' NC='\033[0m' GREEN='\033[0;32m'
B_GREEN='\033[1;32m' MAGENTA="\033[1;95m" BOLD='\033[1m'
CYAN='\033[0;36m' B_RED='\033[1;31m' RESET='\033[0m'
oc_log="/var/log/bc250_oc_install.log"

echo ""
echo -e "  ${RED}RED Pill Suite Active Deployment Profile${RESET} │ ${CYAN}Version:${RESET} ${GREEN}v2.0${RESET} [●]"
echo -e "  ${YELLOW}[●] NOTICE: This deployment process takes approximately 25 minutes from start to finish.${NC}"
echo -e "      ${DIM}Please hold steady and let the background transaction compiler finish completely.${NC}"
echo ""

echo "[●] Stopping obsolete governor daemon services..." &&
systemctl disable --now cyan-skillfish-governor 2>/dev/null || true &&
systemctl disable --now cyan-skillfish-governor-tt 2>/dev/null || true &&
systemctl disable --now oberon-governor 2>/dev/null || true &&

echo "[●] Enabling the filippor/bazzite COPR repository..." &&
sudo copr enable filippor/bazzite <<< y 2>/dev/null || true &&

echo "[●] Cleaning and refreshing rpm-ostree metadata tracking..." &&
sudo rpm-ostree cleanup -m 2>/dev/null || true &&
sudo rpm-ostree refresh-md 2>/dev/null || true &&

echo "[●] Staging Enhanced Cyan Skillfish Governor SMU layers..." &&
rpm-ostree install cyan-skillfish-governor-smu 2>/dev/null || true &&

echo "[●] Injecting performance flags into atomic kernel args (kargs)..." &&
rpm-ostree kargs --append-if-missing=mitigations=off 2>/dev/null || true &&
rpm-ostree kargs --append-if-missing=zswap.enabled=1 2>/dev/null || true &&
rpm-ostree kargs --append-if-missing=zswap.max_pool_percent=25 2>/dev/null || true &&
rpm-ostree kargs --append-if-missing=zswap.compressor=lz4 2>/dev/null || true &&
rpm-ostree kargs --append-if-missing=systemd.zram=0 2>/dev/null || true &&

echo "[●] Tearing down old storage profiles and clearing swap blocks..." &&
sudo swapoff /var/swap/swapfile 2>/dev/null || true &&
sudo rm -f /var/swap/swapfile 2>/dev/null || true &&
sudo btrfs subvolume delete /var/swap 2>/dev/null || true &&

echo "[●] Creating fresh BTRFS subvolume space configurations..." &&
sudo btrfs subvolume create /var/swap 2>/dev/null || true &&
sudo semanage fcontext -a -t var_t /var/swap 2>/dev/null || true &&
sudo restorecon /var/swap 2>/dev/null || true &&

echo "[●] Allocating 32GB contiguous space boundary targets..." &&
sudo btrfs filesystem mkswapfile --size 32G /var/swap/swapfile 2>/dev/null || true &&
sudo semanage fcontext -a -t swapfile_t /var/swap/swapfile 2>/dev/null ||true &&
sudo restorecon /var/swap/swapfile 2>/dev/null ||true &&

echo "[●] Finalizing persistent mounting configurations inside /etc/fstab..." &&
sudo sed -i '/\/var\/swap\/swapfile/d' /etc/fstab &&
sudo bash -c 'echo /var/swap/swapfile none swap defaults,nofail 0 0 >> /etc/fstab' &&

echo "[●] Adjusting virtual memory swappiness parameters (vm.swappiness=180)..." &&
sudo echo 'vm.swappiness = 180' | sudo tee /etc/sysctl.d/99-swappiness.conf || true &&

echo "[●] Compiling lz4 acceleration tables within system initramfs maps..." &&
rpm-ostree initramfs --enable --arg=--add-drivers --arg=lz4 || true

echo ""
echo -e "${B_GREEN}Setup Complete${NC}"
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
