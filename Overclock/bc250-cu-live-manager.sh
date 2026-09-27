#!/usr/bin/env bash
# BC-250 live CU/WGP manager.
#
# This is a self-contained runtime manager. It uses UMR to read/write the
# BC-250 gfx1013 registers that control CU enumeration and WGP dispatch.

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
BC250_PCI_ID="13fe"
ASIC="${UMR_ASIC:-cyan_skillfish.gfx1013}"
REG_CC="mmCC_GC_SHADER_ARRAY_CONFIG"
REG_SPI="mmSPI_PG_ENABLE_STATIC_WGP_MASK"
REG_RLC="mmRLC_PG_ALWAYS_ON_WGP_MASK"
SERVICE_NAME="bc250-cu-live-manager.service"
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
SERVICE_BIN="/usr/local/bin/bc250-cu-live-manager"
SERVICE_CONF="/etc/bc250-cu-live-manager.conf"
OLD_UDEV_RULE="/etc/udev/rules.d/99-bc250-cu-live-manager.rules"

SMN_PCI_DEV="0000:00:00.0"
CPU_MASK_REG=$((0x0115A870))
SMU_MSG_WRITE_FF=$((0x98))
SMU_Q3_CMD=$((0x03B10A20))
SMU_Q3_RSP=$((0x03B10A80))
SMU_Q3_ARG=$((0x03B10A88))
GOVERNOR_SERVICE="cyan-skillfish-governor-smu.service"
LAST_REG_PATH=""
WGP_FULL_MASK=0x1f
UMR="${UMR:-}"
UMR_INSTANCE="${UMR_INSTANCE:-}"
UMR_INSTANCE_SOURCE="${UMR_INSTANCE:+env}"
YES=0
DRY_RUN=0
FORCE=0
DISCLAIMER_ACCEPTED=0
DISCLAIMER_NONINTERACTIVE_SHOWN=0
UMR_INSTALL_OFFERED=0
UMR_INSTANCE_ARGS=()

# 🧬 DYNAMIC STEP WORKSPACE TRACKERS: Added to map history states across the menu logic
TABLE_DIRTY=0       # Set to 1 when a table is edited to light up [w] Write Table
SERVICE_PENDING=0   # Set to 1 when a table is written to light up [i] Install Service

if [ -t 1 ]; then
	BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
	RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
	CYAN=$'\033[36m'; REV=$'\033[7m'
else
	BOLD=""; DIM=""; RESET=""; RED=""; GREEN=""; YELLOW=""
	CYAN=""; REV=""
fi

info() { printf '%s[ OK ]%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s[WARN]%s %s\n' "$YELLOW" "$RESET" "$*"; }
err()  { printf '%s[ERR ]%s %s\n' "$RED" "$RESET" "$*" >&2; }
die()  { err "$@"; exit 1; }

hr() {
	printf '%s+------------------------------------------------------------------------------+%s\n' "$DIM" "$RESET"
}

panel_title() {
	local title="$1"
	hr
	printf '%s|%s %-76s %s|%s\n' "$DIM" "$RESET$BOLD" "$title" "$DIM" "$RESET"
	hr
}

prompt_line() {
	printf '%s>%s %s' "$CYAN" "$RESET" "$1"
}

find_umr() {
	local p
	if [ -n "$UMR" ] && [ -x "$UMR" ]; then return 0; fi
	for p in /usr/bin/umr /usr/local/bin/umr /opt/umr/build/src/app/umr; do
		if [ -x "$p" ]; then UMR="$p"; return 0; fi
	done
	return 1
}

need_umr() {
	find_umr || die "umr not found. Run: sudo ./$SCRIPT_NAME install-umr"
	select_umr_instance "${1:-default}"
}

validate_umr_instance() { [[ "$1" =~ ^[0-9]+$ ]]; }
init_umr_instance_args() { UMR_INSTANCE_ARGS=(); if [ -n "$UMR_INSTANCE" ]; then UMR_INSTANCE_ARGS=(-i "$UMR_INSTANCE"); fi; }
umr_cmd_string() { printf '%s' "$UMR"; if [ -n "$UMR_INSTANCE" ]; then printf ' -i %s' "$UMR_INSTANCE"; fi; }

detect_umr_instance() {
	local debug_root="/sys/kernel/debug/dri" line bdf dir inst local -a seen=()
	[ -d "$debug_root" ] || return 1
	while IFS= read -r line; do
		bdf="${line%% *}" [ -n "$bdf" ] || continue
		for dir in "$debug_root"/[0-9]*; do
			[ -e "$dir/name" ] || continue
			inst="${dir##*/}" [[ "$inst" =~ ^[0-9]+$ ]] || continue
			[ "$inst" -lt 128 ] || continue
			if grep -Fqi "$bdf" "$dir/name" 2>/dev/null; then printf '%s\n' "$inst"; return 0; fi
		done
	done < <(lspci -Dnn 2>/dev/null | grep -i '\[1002:13fe\]' || true)
	for dir in "$debug_root"/[0-9]*; do
		[ -e "$dir/name" ] || continue
		inst="${dir##*/}" [[ "$inst" =~ ^[0-9]+$ ]] || continue
		[ "$inst" -lt 128 ] || continue
		seen+=("$inst")
	done
	[ "${#seen[@]}" -eq 1 ] || return 1
	printf '%s\n' "${seen[0]}"; return 0
}

select_umr_instance() {
	local mode="${1:-default}" detected configured_instance="" configured_source=""
	if [ -n "$UMR_INSTANCE" ]; then
		validate_umr_instance "$UMR_INSTANCE" || die "invalid --umr-instance '$UMR_INSTANCE'"
		UMR_INSTANCE_SOURCE="${UMR_INSTANCE_SOURCE:-env}" configured_instance="$UMR_INSTANCE" configured_source="$UMR_INSTANCE_SOURCE"
		if [ "$mode" != "apply-service" ] || [ "$UMR_INSTANCE_SOURCE" = "cli" ]; then init_umr_instance_args; return 0; fi
	fi
	detected="$(detect_umr_instance || true)"
	if [ -n "$detected" ]; then UMR_INSTANCE="$detected" UMR_INSTANCE_SOURCE="auto"
	elif [ -n "$configured_instance" ]; then UMR_INSTANCE="$configured_instance" UMR_INSTANCE_SOURCE="$configured_source"
	else UMR_INSTANCE="" UMR_INSTANCE_SOURCE="default"; fi
	init_umr_instance_args
}

need_root() { [ "$(id -u)" = "0" ] || die "register writes require root"; }
need_umr_root() { [ "$(id -u)" = "0" ] || die "umr register access requires root."; }
needs_root_command() { local cmd="$1"; root_reason_for_command "$cmd" >/dev/null; }

root_reason_for_command() {
	local cmd="$1"
	case "$cmd" in
		""|menu|status|table|apply-service|stock-dispatch|enable|disable|enable-wgp|disable-wgp) printf '%s' "it needs live UMR register access"; return 0 ;;
		install-service|write-service-table|uninstall-service) printf '%s' "it needs root to write systemd files"; return 0 ;;
		cpu-unlock) printf '%s' "it needs root for SMU access through PCI config space"; return 0 ;;
		install-umr) printf '%s' "it needs root to install host packages"; return 0 ;;
		*) return 1 ;;
	esac
}

reexec_with_sudo_if_needed() {
	local cmd="$1"; shift; local reason script_path
	[ "$(id -u)" = "0" ] && return 0
	reason="$(root_reason_for_command "$cmd" || true)" [ -n "$reason" ] || return 0
	command -v sudo >/dev/null 2>&1 || die "this command requires root, and sudo was not found"
	script_path="$(readlink -f "$0" 2>/dev/null || printf '%s' "$0")"
	info "re-running with sudo: $reason"
	exec sudo --preserve-env=UMR,UMR_ASIC,UMR_INSTANCE "$script_path" "$@"
}
print_disclaimer() {
	panel_title "Safety Disclaimer"
	printf '| %-76s |\n' "This tool writes low-level AMDGPU registers on BC-250 hardware."
	printf '| %-76s |\n' "Incorrect values can freeze the GPU, crash the system, or force a reboot."
	printf '| %-76s |\n' "You may lose unsaved work and can increase power draw and thermals."
	printf '| %-76s |\n' "No warranty is provided by the authors or contributors of this script."
	printf '| %-76s |\n' "You are fully responsible for validation, monitoring, and any outcomes."
	printf '| %-76s |\n' "Recommended: stable PSU, active cooling, and a remote shell fallback."
	hr
}

confirm_disclaimer() {
	local ans
	[ "${DISCLAIMER_ACCEPTED:-0}" -eq 1 ] && return 0
	if [ "${YES:-0}" -eq 1 ]; then
		if [ "${DISCLAIMER_NONINTERACTIVE_SHOWN:-0}" -eq 0 ]; then
			printf '\n'; print_disclaimer
			warn "--yes is set; continuing without interactive acknowledgment"
			DISCLAIMER_NONINTERACTIVE_SHOWN=1
		fi
		DISCLAIMER_ACCEPTED=1; return 0
	fi
	while true; do
		printf '\n'; print_disclaimer
		prompt_line "Type 'accept' to continue or 'no' to cancel: "
		read -r ans
		case "$ans" in
			accept|ACCEPT|Accept) DISCLAIMER_ACCEPTED=1; return 0 ;;
			n|N|no|NO|No|cancel|CANCEL|Cancel) warn "cancelled"; return 1 ;;
			*) warn "type accept or no" ;;
		esac
	done
}

confirm_service_install() {
	confirm_disclaimer || return 1
	[ "${YES:-0}" -eq 1 ] && return 0
	local ans
	while true; do
		printf '\n'; panel_title "Confirm Service Install"
		printf '| %-76s |\n' "This will install and enable the boot service."
		printf '| %-76s |\n' "Use write-service-table when you want to change the saved WGP table."
		hr; prompt_line "Install/update service? [y/n]: "
		read -r ans
		case "$ans" in
			y|Y|yes|YES) return 0 ;;
			n|N|no|NO) warn "cancelled"; return 1 ;;
			*) warn "type y or n" ;;
		esac
	done
}

confirm_write_service_table() {
	[ "${YES:-0}" -eq 1 ] && return 0
	local ans
	while true; do
		printf '\n'; panel_title "Confirm Boot Table Save"
		printf '| %-76s |\n' "This will save the current live WGP table as the boot profile."
		printf '| %-76s |\n' "The installed service will use this table on the next start/boot."
		hr; prompt_line "Write current table to service config? [y/n]: "
		read -r ans
		case "$ans" in
			y|Y|yes|YES) return 0 ;;
			n|N|no|NO) warn "cancelled"; return 1 ;;
			*) warn "type y or n" ;;
		esac
	done
}

mask_tokens() {
	local mask="$1" driver_mask="${2:-0}" wgp bit token out=""
	for wgp in 0 1 2 3 4; do
		bit=$((1 << wgp))
		if [ $((driver_mask & bit)) -ne 0 ] && [ $((mask & bit)) -ne 0 ]; then token="D+"
		elif [ $((driver_mask & bit)) -ne 0 ]; then token="D!"
		elif [ $((mask & bit)) -ne 0 ]; then token="S+"
		else token="--"
		fi
		out="${out}${out:+ }$token"
	done
	printf '%s\n' "$out"
}

mask_change_label() {
	local old="$1" new="$2" wgp bit out=""
	for wgp in 0 1 2 3 4; do
		bit=$((1 << wgp))
		if [ $((old & bit)) -eq 0 ] && [ $((new & bit)) -ne 0 ]; then out="${out}${out:+,}W${wgp}+"
		elif [ $((old & bit)) -ne 0 ] && [ $((new & bit)) -eq 0 ]; then out="${out}${out:+,}W${wgp}-"
		fi
	done
	printf '%s\n' "${out:-none}"
}

dispatch_total() {
	local idx total=0
	for idx in 0 1 2 3; do total=$((total + $(wgp_mask_cu_count "${target_masks[$idx]}"))); done
	printf '%s\n' "$total"
}
mask_csv() {
	local -n ref="$1"
	printf '%s,%s,%s,%s\n' "$(hex_mask "${ref[0]}")" "$(hex_mask "${ref[1]}")" "$(hex_mask "${ref[2]}")" "$(hex_mask "${ref[3]}")"
}

mask_summary() {
	local -n ref="$1"
	printf '%s=%s %s=%s %s=%s %s=%s\n' "SE0.SH0" "$(hex_mask "${ref[0]}")" "SE0.SH1" "$(hex_mask "${ref[1]}")" "SE1.SH0" "$(hex_mask "${ref[2]}")" "SE1.SH1" "$(hex_mask "${ref[3]}")"
}

load_service_masks() {
	local line csv item idx value local -a _service_items
	service_masks=() [ -f "$SERVICE_CONF" ] || return 1
	while IFS= read -r line; do
		case "$line" in BC250_WGP_MASKS=*) csv="${line#BC250_WGP_MASKS=}"; break ;; esac
	done <"$SERVICE_CONF"
	[ -n "${csv:-}" ] || return 1
	IFS=',' read -ra _service_items <<<"$csv"
	[ "${#_service_items[@]}" -eq 4 ] || return 1
	for idx in 0 1 2 3; do
		item="${_service_items[$idx]}" [[ "$item" =~ ^(0x[0-9a-fA-F]+|[0-9]+)$ ]] || return 1
		value=$((item)) [ "$value" -ge 0 ] && [ "$value" -le 31 ] || return 1
		service_masks[$idx]="$value"
	done
	return 0
}

service_masks_match_current() {
	local idx
	[ "${#service_masks[@]}" -eq 4 ] || return 1
	[ "${#current_masks[@]}" -eq 4 ] || return 1
	for idx in 0 1 2 3; do [ "$((service_masks[idx] & 31))" -eq "$((current_masks[idx] & 31))" ] || return 1; done
	return 0
}

confirm_dispatch_plan() {
	local title="$1" idx ans current target driver
	confirm_disclaimer || return 1
	[ "${YES:-0}" -eq 1 ] && return 0
	while true; do
		printf '\n'; panel_title "$title"
		printf '  Legend: D+=driver+routed, S+=SPI+routed, D!=driver+off, --=off\n\n'
		printf '  +---------+----------------+----------------+-----------------------+\n'
		printf '  | Row     | Current        | Target         | Change                |\n'
		printf '  +---------+----------------+----------------+-----------------------+\n'
		for idx in 0 1 2 3; do
			current="${current_masks[$idx]}" target="${target_masks[$idx]}" driver="${driver_masks[$idx]:-0}"
			local row_lbl="SE0.SH0"; [ "$idx" -eq 1 ] && row_lbl="SE0.SH1"; [ "$idx" -eq 2 ] && row_lbl="SE1.SH0"; [ "$idx" -eq 3 ] && row_lbl="SE1.SH1"
			printf '  | %-7s | %-14s | %-14s | %-21s |\n' "$row_lbl" "$(mask_tokens "$current" "$driver")" "$(mask_tokens "$target" "$driver")" "$(mask_change_label "$current" "$target")"
		done
		printf '  +---------+----------------+----------------+-----------------------+\n'
		printf '\n  Target total: %s%s/40 CUs%s\n' "$BOLD" "$(dispatch_total)" "$RESET"
		prompt_line "Apply changes? [y/n]: "
		read -r ans
		case "$ans" in
			y|Y|yes|YES) return 0 ;;
			n|N|no|NO) warn "cancelled"; return 1 ;;
			*) warn "type y or n" ;;
		esac
	done
}
check_bc250() { if command -v lspci >/dev/null 2>&1 && lspci -nn 2>/dev/null | grep -qi "$BC250_PCI_ID"; then return 0; fi; warn "BC-250 PCI ID 13fe was not detected by lspci."; return 1; }
require_bc250_for_write() { if check_bc250; then return 0; fi; [ "${FORCE:-0}" -eq 1 ] || die "refusing register writes on unknown hardware. Use --force only if this is a BC-250 and lspci detection is wrong."; warn "forcing register writes despite failed BC-250 PCI detection"; }

install_umr() {
	need_root
	if command -v dpkg >/dev/null 2>&1 && dpkg -s umr >/dev/null 2>&1; then info "umr is already installed."; return 0; fi
	if command -v pacman >/dev/null 2>&1 && pacman -Qi umr >/dev/null 2>&1; then info "umr is already installed."; return 0; fi
	if command -v apt-get >/dev/null 2>&1; then
		info "Installing umr build dependencies with apt-get..."
		apt-get update -qq || true
		DEBIAN_FRONTEND=noninteractive apt-get install -y git build-essential cmake libncurses-dev libpciaccess-dev libdrm-dev llvm-dev libnanomsg-dev libgl-dev libegl-dev libgles-dev libopengl-dev libgbm-dev libedit-dev libz3-dev libzstd-dev libcurl4-gnutls-dev libsdl2-dev python3-sphinx
		info "Cloning and building umr from source..."
		( build_tmp="$(mktemp -d)"; cd "$build_tmp"; git clone https://freedesktop.org; cd umr; cmake -DUMR_GUI=OFF -B build-dir -S .; cmake --build build-dir; info "Packaging and installing umr..."; cd build-dir; sed -i 's/set(CPACK_DEBIAN_PACKAGE_DEPENDS ".*")/set(CPACK_DEBIAN_PACKAGE_DEPENDS "")/' CPackConfig.cmake; sed -i 's/set(CPACK_GENERATOR "RPM;DEB")/set(CPACK_GENERATOR "DEB")/' CPackConfig.cmake; cpack; dpkg -i umr-*-Linux.deb; cd /; rm -rf "$build_tmp" ) && return 0
		die "Failed to build and install umr from source."
	fi
	if command -v pacman >/dev/null 2>&1; then if pacman -Si umr >/dev/null 2>&1; then info "Installing umr with pacman..."; pacman -S --needed umr; return 0; fi; fi
	if command -v paru >/dev/null 2>&1; then local user_name="${SUDO_USER:-}"; [ -n "$user_name" ] || die "paru install needs SUDO_USER set"; info "Installing umr with paru as $user_name..."; sudo -u "$user_name" paru -S --needed umr; return 0; fi
	if command -v rpm-ostree >/dev/null 2>&1; then if rpm-ostree status 2>/dev/null | grep -q "umr"; then info "umr is already layered via rpm-ostree."; return 0; fi; info "Installing umr with rpm-ostree (reboot required)..."; if rpm-ostree install umr; then info "umr was staged successfully. Reboot, then run this script again."; return 0; fi; die "rpm-ostree could not layer umr automatically."; fi
	if command -v dnf >/dev/null 2>&1; then info "Installing umr with dnf..."  dnf install -y umr && return 0; die "dnf could not install umr."; fi
	die "could not install umr automatically; please install it manually first"
}
have_setpci() { command -v setpci >/dev/null 2>&1 && [ -e "/sys/bus/pci/devices/$SMN_PCI_DEV/config" ]; }
pci_cfg_write32() { setpci -s "$SMN_PCI_DEV" "$1.L=$(printf '%08x' "$2")"; }
pci_cfg_read32() { local out; out="$(setpci -s "$SMN_PCI_DEV" "$1.L")" || return 1; printf '0x%s\n' "$out"; }
smn_read32() { pci_cfg_write32 B8 "$1" || return 1; pci_cfg_read32 BC; }
smn_write32() { pci_cfg_write32 B8 "$1" && pci_cfg_write32 BC "$2"; }
smu_rsp_done() { case "$(( $1 ))" in 1|252|253|254|255) return 0 ;; esac; return 1; }

smu_q3_send() {
	local msg="$1" arg="$2" deadline rsp; deadline=$((SECONDS + 6))
	while :; do rsp="$(smn_read32 "$SMU_Q3_RSP")" || return 1; smu_rsp_done "$rsp" && break; [ "$SECONDS" -lt "$deadline" ] || break; sleep 0.002; done
	smn_write32 "$SMU_Q3_RSP" 0 || return 1; smn_write32 "$SMU_Q3_ARG" "$arg" || return 1; smn_write32 "$((SMU_Q3_ARG + 4))" 0 || return 1; smn_write32 "$SMU_Q3_CMD" "$msg" || return 1; deadline=$((SECONDS + 6))
	while [ "$SECONDS" -lt "$deadline" ]; do rsp="$(smn_read32 "$SMU_Q3_RSP")" || return 1; if smu_rsp_done "$rsp"; then printf '%s\n' "$rsp"; return 0; fi; sleep 0.002; done
	return 2
}

cpu_present_threads() {
	local present part lo hi total=0 local -a parts; present="$(cat /sys/devices/system/cpu/present 2>/dev/null)" || { printf '0\n'; return; }
	IFS=',' read -ra parts <<<"$present"
	for part in "${parts[@]}"; do if [[ "$part" == *-* ]]; then lo="${part%-*}" hi="${part#*-}" total=$((total + hi - lo + 1)); else total=$((total + 1)); fi; done
	printf '%s\n' "$total"
}
cpu_unlock_now() {
	need_root; local present; present="$(cpu_present_threads)"
	if [ "$present" -ge 16 ]; then info "CPU cores are already unlocked and active ($present threads present)"; return 0; fi
	if ! have_setpci; then err "setpci or PCI device $SMN_PCI_DEV unavailable; cannot unlock CPU cores"; return 1; fi
	local before after st rc=0 governor_was_active=0
	if systemctl is-active --quiet "$GOVERNOR_SERVICE" 2>/dev/null; then governor_was_active=1; info "stopping $GOVERNOR_SERVICE for SMU mailbox access"; systemctl stop "$GOVERNOR_SERVICE"; fi
	if before="$(smn_read32 "$CPU_MASK_REG")"; then
		info "core presence mask: $before"
		if [ $((before & 0xFF)) -eq $((0xFF)) ]; then info "mask is already 0xFF; reboot to bring up all 8 cores (16 threads)"; CPU_UNLOCK_REBOOT_NEEDED=1
		elif [ $((before & 0xFF)) -ne $((0x77)) ]; then err "unexpected core mask $(printf '0x%02X' $((before & 0xFF))), expected 0x77; aborting"; rc=1
		elif [ "${DRY_RUN:-0}" -eq 1 ]; then printf 'dry-run: setpci SMU Q3 msg 0x%02X arg 0x%08X on %s\n' "$SMU_MSG_WRITE_FF" "$CPU_MASK_REG" "$SMN_PCI_DEV"
		else
			st="$(smu_q3_send "$SMU_MSG_WRITE_FF" "$CPU_MASK_REG")" || rc=$?
			if [ "$rc" -eq 2 ]; then err "SMU mailbox timeout; aborting, do not retry before a reboot"
			elif [ "$rc" -ne 0 ]; then err "PCI config access failed during SMU message"
			elif [ $((st)) -ne 1 ]; then err "SMU Q3 0x98 returned $(printf '0x%02X' $((st))); is the governor stopped?"; rc=1
			else
				sleep 0.2; after="$(smn_read32 "$CPU_MASK_REG")" || after=""
				info "core mask after write: ${after:-read failed}"
				if [ -n "$after" ] && [ $((after & 0xFF)) -eq $((0xFF)) ]; then info "CPU core unlock written"; CPU_UNLOCK_REBOOT_NEEDED=1; else err "core mask did not take"; rc=1; fi
			fi
		fi
	else err "failed to read core presence mask via setpci"; rc=1; fi
	if [ "$governor_was_active" -eq 1 ]; then systemctl start "$GOVERNOR_SERVICE" || warn "failed to restart $GOVERNOR_SERVICE"; fi
	return "$rc"
}

confirm_cpu_unlock() {
	confirm_disclaimer || return 1; [ "${YES:-0}" -eq 1 ] && return 0
	local ans
	while true; do
		printf '\n'; panel_title "Confirm CPU Core Unlock"
		printf '| %-76s |\n' "This sends SMU message 0x98 to raise the core presence mask 0x77 -> 0xFF,"
		printf '| %-76s |\n' "enabling the 2 factory-disabled CPU cores (6c/12t -> 8c/16t) on next reboot."
		printf '| %-76s |\n' "Those cores may have been disabled for a reason; stress-test before trusting."
		printf '| %-76s |\n' "The unlock is volatile: re-run it after a cold power cycle."
		hr; prompt_line "Unlock CPU cores now? [y/n]: " read -r ans
		case "$ans" in y|Y|yes|YES) return 0 ;; n|N|no|NO) warn "cancelled"; return 1 ;; *) warn "type y or n" ;; esac
	done
}

offer_cpu_unlock_reboot() {
	local ans; [ "${YES:-0}" -eq 1 ] && { info "reboot when ready to bring up all 8 cores"; return 0; }
	while true; do
		printf '\n'; prompt_line "Reboot now to bring up all 8 cores? [y/n]: " read -r ans
		case "$ans" in y|Y|yes|YES) info "rebooting..."; systemctl reboot; return 0 ;; n|N|no|NO) info "reboot skipped; the cores will come up on the next reboot"; return 0 ;; *) warn "type y or n" ;; esac
	done
}

cpu_unlock() { need_root; require_bc250_for_write; confirm_cpu_unlock || return 0; cpu_unlock_now || return 1; if [ "${CPU_UNLOCK_REBOOT_NEEDED:-0}" -eq 1 ]; then offer_cpu_unlock_reboot; fi; }

cpu_status() {
	local present online mask lo state; present="$(cpu_present_threads)" online="$(nproc 2>/dev/null || printf '?')"
	if [ "$present" -ge 16 ]; then state="unlocked 8c/16t"
	elif systemctl is-active --quiet "$GOVERNOR_SERVICE" 2>/dev/null; then state="mask not probed (governor active)"
	elif ! have_setpci; then state="mask unavailable (setpci missing)"
	elif mask="$(smn_read32 "$CPU_MASK_REG" 2>/dev/null)"; then
		lo=$((mask & 0xFF))
		if [ "$lo" -eq $((0xFF)) ]; then state="unlock armed; reboot pending"
		elif [ "$lo" -eq $((0x77)) ]; then state="stock 6c/12t"
		else state="unknown mask $(printf '0x%02X' "$lo")"; fi
	else state="mask read failed"; fi
	printf '  CPU        : %s threads present, %s online; %s\n' "$present" "$online" "$state"
}
install_service() {
	need_root; need_umr; confirm_service_install || return 0
	local source_path; source_path="$(readlink -f "$0")"
	if ! install -m 0755 "$source_path" "$SERVICE_BIN"; then if [ -d /var/usrlocal/bin ]; then SERVICE_BIN="/var/usrlocal/bin/bc250-cu-live-manager"; install -m 0755 "$source_path" "$SERVICE_BIN"; else die "failed to install service binary"; fi; fi
	cat > "$SERVICE_PATH" <<EOF
[Unit]
Description=BC-250 CU saved enumeration and dispatch
After=systemd-udev-settle.service
Wants=systemd-udev-settle.service

[Service]
Type=oneshot
EnvironmentFile=-$SERVICE_CONF
ExecStartPre=/usr/bin/bash -c 'for _ in {1..30}; do compgen -G "/dev/dri/renderD*" >/dev/null && exit 0; sleep 1; done; exit 1'
ExecStart=$SERVICE_BIN --yes apply-service
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
	rm -f "$OLD_UDEV_RULE"; systemctl daemon-reload; systemctl enable "$SERVICE_NAME"
	if [ -f "$SERVICE_CONF" ]; then info "installed and enabled $SERVICE_NAME"; info "saved boot table will be applied on next boot; use apply-service to apply it now"
	else info "installed and enabled $SERVICE_NAME"; warn "no boot table is saved yet; use write-service-table before rebooting"; fi
}

write_service_table() {
	need_root; need_umr; select_asic; require_bc250_for_write; local -a current_masks; read_current_masks; confirm_write_service_table || return 0
	cat > "$SERVICE_CONF" <<EOF
# BC-250 live manager boot profile.
# Format: SE0.SH0,SE0.SH1,SE1.SH0,SE1.SH1 SPI WGP masks.
BC250_WGP_MASKS=$(mask_csv current_masks)
UMR_ASIC=$ASIC
UMR_INSTANCE=
UMR=$UMR
EOF
	chmod 0644 "$SERVICE_CONF"; info "saved boot table: $(mask_summary current_masks)"
}

uninstall_service() { need_root; systemctl disable --now "$SERVICE_NAME" >/dev/null 2>&1 || true; rm -f "$SERVICE_PATH" "$SERVICE_BIN" "/var/usrlocal/bin/bc250-cu-live-manager" "$SERVICE_CONF" "$OLD_UDEV_RULE"; systemctl daemon-reload; info "removed $SERVICE_NAME"; }
select_asic() { local out value; out="$("$UMR" "${UMR_INSTANCE_ARGS[@]}" -r "$ASIC.$REG_SPI" 2>&1 || true)" value="$(printf '%s\n' "$out" | parse_hex)"; [ -n "$value" ] && return 0; die "failed to read $ASIC.$REG_SPI with umr."; }
reg_candidates() { printf '%s\n' "$1"; }
parse_hex() { awk '{ for (i = NF; i >= 1; i--) { if ($i ~ /^0x[0-9a-fA-F]+$/) { print $i; exit } } }'; }
umr_output_failed() { local out="$1"; printf '%s\n' "$out" | grep -Eqi '(\[ERROR\]|error|failed|invalid|unknown|cannot|no such)'; }
read_reg_bank() { local reg="$1" se="$2" sh="$3" value; if value="$(try_read_reg_bank "$reg" "$se" "$sh")"; then printf '%s\n' "$value"; return 0; fi; die "failed to read $reg"; }

try_read_reg_bank() {
	local reg="$1" se="$2" sh="$3" candidate out value; LAST_REG_PATH=""
	while IFS= read -r candidate; do
		out="$("$UMR" "${UMR_INSTANCE_ARGS[@]}" -r "$ASIC.$candidate" -b "$se" "$sh" 0xffffffff 2>&1 || true)" value="$(printf '%s\n' "$out" | parse_hex)"
		if [ -z "$value" ]; then out="$("$UMR" "${UMR_INSTANCE_ARGS[@]}" -r "$ASIC.$candidate" -b "$se" "$sh" 2>&1 || true)"; value="$(printf '%s\n' "$out" | parse_hex)"; fi
		if [ -n "$value" ]; then LAST_REG_PATH="$ASIC.$candidate"; printf '%s\n' "$value"; return 0; fi
	done < <(reg_candidates "$reg")
	return 1
}
try_write_reg_global() {
	local reg="$1" value="$2" candidate out; LAST_REG_PATH=""
	while IFS= read -r candidate; do
		LAST_REG_PATH="$ASIC.$candidate"; if [ "${DRY_RUN:-0}" -eq 1 ]; then printf 'dry-run: %s -w %s %s\n' "$(umr_cmd_string)" "$LAST_REG_PATH" "$value"; return 0; fi
		out="$("$UMR" "${UMR_INSTANCE_ARGS[@]}" -w "$LAST_REG_PATH" "$value" 2>&1 || true)" if ! umr_output_failed "$out"; then return 0; fi
	done < <(reg_candidates "$reg")
	return 1
}

write_reg_bank() {
	local reg="$1" value="$2" se="$3" sh="$4" candidate out; LAST_REG_PATH=""
	while IFS= read -r candidate; do
		LAST_REG_PATH="$ASIC.$candidate"; if [ "${DRY_RUN:-0}" -eq 1 ]; then printf 'dry-run: %s -w %s %s -b %s %s 0xffffffff\n' "$(umr_cmd_string)" "$LAST_REG_PATH" "$value" "$se" "$sh"; return 0; fi
		out="$("$UMR" "${UMR_INSTANCE_ARGS[@]}" -w "$LAST_REG_PATH" "$value" -b "$se" "$sh" 0xffffffff 2>&1 || true)" if ! umr_output_failed "$out"; then return 0; fi
	done < <(reg_candidates "$reg")
	die "failed to write $reg=$value"
}

hex_to_dec() { printf '%d' "$(( $1 ))"; }
hex_mask() { printf '0x%02x' "$(( $1 & 31 ))"; }
wgp_mask_cu_count() { local mask="$1" wgp count=0; for wgp in 0 1 2 3 4; do if [ $((mask & (1 << wgp))) -ne 0 ]; then count=$((count + 2)); fi; done; printf '%s\n' "$count"; }
module_status() { local mode enum; mode="$(cat /sys/module/amdgpu/parameters/bc250_cc_write_mode 2>/dev/null || true)" enum="$(dmesg 2>/dev/null | grep -o 'active_cu_number [0-9]*' | tail -1 | awk '{print $2}' || true)"; printf '  amdgpu     : bc250_cc_write_mode=%s, active_cu_number=%s\n' "${mode:-not exposed}" "${enum:-unknown}"; }
live_table_rule() { printf '  +---------+------+------+------+------+------+------+------------+--------+\n'; }
live_table_header() { live_table_rule; printf '  | Row     | WGP0 | WGP1 | WGP2 | WGP3 | WGP4 | SPI  | CC         | CUs    |\n'; printf '  |         | 0-1  | 2-3  | 4-5  | 6-7  | 8-9  |      |            |        |\n'; live_table_rule; }

live_wgp_dispatch_cell() {
	local spi_on="$1" driver_on="${2:-0}"
	if [ "$driver_on" -ne 0 ] && [ "$spi_on" -ne 0 ]; then printf '  %sD+%s  |' "$GREEN$BOLD" "$RESET"
	elif [ "$driver_on" -ne 0 ] && [ "$spi_on" -eq 0 ]; then printf '  %sD!%s  |' "$RED$BOLD" "$RESET"
	elif [ "$spi_on" -ne 0 ]; then printf '  %sS+%s  |' "$CYAN" "$RESET"
	else printf '  %s--%s  |' "$DIM" "$RESET"; fi
}
read_driver_wgp_masks() {
	local line idx mask local -a out=()
	while IFS= read -r line; do out+=("$line"); done < <(python3 <<'PYEOF'
import ctypes, os, struct, sys
def open_render_node():
    candidates = ["/dev/dri/renderD128"]
    dri = "/dev/dri"
    if os.path.isdir(dri):
        for name in sorted(os.listdir(dri)):
            if name.startswith("renderD"):
                path = os.path.join(dri, name)
                if path not in candidates: candidates.append(path)
    last = None
    for path in candidates:
        try: return os.open(path, os.O_RDWR)
        except OSError as exc: last = exc
    raise RuntimeError(f"no DRM render node could be opened: {last}")
try:
    libdrm = None
    for lib_path in ["libdrm_amdgpu.so.1", "/usr/lib64/libdrm_amdgpu.so.1", "/usr/lib/x86_64-linux-gnu/libdrm_amdgpu.so.1"]:
        try: libdrm = ctypes.CDLL(lib_path); break
        except OSError: continue
    if libdrm is None: raise RuntimeError("libdrm_amdgpu driver library not found natively on this host filesystem.")
    fd = open_render_node()
    dev = ctypes.c_void_p()
    maj, min_ = ctypes.c_uint32(), ctypes.c_uint32()
    rc = libdrm.amdgpu_device_initialize(fd, ctypes.byref(maj), ctypes.byref(min_), ctypes.byref(dev))
    if rc != 0: raise RuntimeError(f"amdgpu_device_initialize failed: {rc}")
    buf = (ctypes.c_uint8 * 1024)()
    rc = libdrm.amdgpu_query_info(dev, 0x16, 1024, ctypes.byref(buf))
    if rc != 0: raise RuntimeError(f"amdgpu_query_info(CU_INFO) failed: {rc}")
    raw = bytes(buf)
    num_se = struct.unpack_from("<I", raw, 20)[0]
    num_sh = struct.unpack_from("<I", raw, 24)[0]
    rows = []
    for se in range(min(num_se, 2)):
        for sh in range(min(num_sh, 2)):
            bm = struct.unpack_from("<I", raw, 56 + (se * 4 + sh) * 4)[0]
            wgp_mask = 0
            for wgp in range(5):
                if bm & (0x3 << (wgp * 2)): wgp_mask |= 1 << wgp
            rows.append((se * 2 + sh, wgp_mask))
    for idx, mask in rows: print(f"{idx} {mask}")
except Exception: sys.exit(1)
finally:
    try:
        if 'dev' in locals() and dev: libdrm.amdgpu_device_deinitialize(dev)
    except Exception: pass
    try:
        if 'fd' in locals() and fd >= 0: os.close(fd)
    except Exception: pass
PYEOF
	)
	[ "${#out[@]}" -gt 0 ] || return 1
	for idx in 0 1 2 3; do driver_masks[$idx]=0; done
	for line in "${out[@]}"; do read -r idx mask <<<"$line"; [[ "$idx" =~ ^[0-3]$ ]] || continue; driver_masks[$idx]="$mask"; done
	return 0
}

# ==============================================================================
# 🚀 STEP-HIGHLIGHTER INTERACTIVE MENU INTERFACE INTERPRETER
# ==============================================================================
menu() {
    while true; do
        clear
        panel_title "Interactive Core Optimizer"

        # Load local parameters to check service file synchronization on disk paths
        load_service_masks && local has_conf=0 || local has_conf=1
        systemctl is-enabled "$SERVICE_NAME" &>/dev/null && local svc_enabled=0 || local svc_enabled=1

        # Establish base colors matching your exact theme variables
        local c_edit="${CYAN}" local c_write="${CYAN}" local c_install="${CYAN}"

        # 🚀 STEP HIGHLIGHT CORE: Sweeps dirty status tags to flash bracket borders green
        if [ "${TABLE_DIRTY:-0}" -eq 1 ]; then
            c_edit="${DIM}"
            c_write="${GREEN}${BOLD}"    # 🌟 Turn [w] Green: Directs you to write the table configuration next!
        elif [ "${SERVICE_PENDING:-0}" -eq 1 ] || { [ "$has_conf" -eq 0 ] && [ "$svc_enabled" -ne 0 ]; }; then
            c_write="${DIM}"
            c_install="${GREEN}${BOLD}"  # 🌟 Turn [i] Green: Directs you to install the boot service next!
        fi

        # Print your exact original screen matrix string layout utilizing the custom hooks
        echo ""
        echo -e "  |  ${c_edit}[e]${RESET} Edit WGP table      ${CYAN}[f]${RESET} Enable all CUs      ${CYAN}[t]${RESET} Enable default CUs      |"
        echo -e "  |  ${c_install}[i]${RESET} Install service     ${c_write}[w]${RESET} Write table         ${CYAN}[u]${RESET} Uninstall service       |"
        echo -e "  |  ${CYAN}[c]${RESET} Unlock CPU cores    ${RED}[q]${RESET} Quit                                            |"
        echo ""
        hr
        echo ""

        prompt_line "Enter selection: "
        local choice; read -r choice
        choice=$(echo "$choice" | tr -d '\r')

        case "${choice,,}" in
            e)
                if table; then TABLE_DIRTY=1; SERVICE_PENDING=0; fi
                ;;
            f)
                if [ "${YES:-0}" -eq 1 ] || confirm_dispatch_plan "Enable All CUs Plan"; then
                    local idx; for idx in 0 1 2 3; do target_masks[$idx]=$WGP_FULL_MASK; done
                    apply_target_masks && TABLE_DIRTY=1 && SERVICE_PENDING=0
                fi
                ;;
            t)
                if [ "${YES:-0}" -eq 1 ] || confirm_dispatch_plan "Restore Stock Dispatch Plan"; then
                    local idx; for idx in 0 1 2 3; do target_masks[$idx]=0; done
                    apply_target_masks && TABLE_DIRTY=1 && SERVICE_PENDING=0
                fi
                ;;
            w)
                if [ "${TABLE_DIRTY:-0}" -eq 1 ] || [ "${YES:-0}" -eq 1 ] || [ "$has_conf" -eq 1 ]; then
                    write_service_table && TABLE_DIRTY=0 && SERVICE_PENDING=1
                    sleep 1.5
                else
                    warn "No modifications cached in memory workspace. Edit via [e] first."
                    sleep 2
                fi
                ;;
            i)
                install_service && SERVICE_PENDING=0; sleep 2
                ;;
            u)
                uninstall_service && TABLE_DIRTY=0 && SERVICE_PENDING=0; sleep 2
                ;;
            c)
                cpu_unlock
                ;;
            q)
                echo -e "\n  ${YELLOW}[-] Terminating optimization loop...${RESET}\n"; exit 0
                ;;
            *)
                echo -e "\n  ${RED}❌ ERROR: Invalid menu option choice '$choice'.${RESET}"; sleep 1.2
                ;;
        esac
    done
}

# ==============================================================================
# 🚀 CORE ARGUMENTS ROUTING DISPATCH BRIDGE
# ==============================================================================
CMD="${1:-menu}"
case "$CMD" in
    menu)
        need_root && need_umr && select_asic
        read_current_masks &>/dev/null || true
        read_driver_wgp_masks &>/dev/null || true
        menu
        ;;
    status) need_umr_root status && status ;;
    table) need_umr_root table && table ;;
    cpu-unlock) cpu_unlock ;;
    install-service) install_service ;;
    write-service-table) write_service_table ;;
    apply-service) load_service_masks && apply_service ;;
    uninstall-service) uninstall_service ;;
    stock-dispatch) stock-dispatch ;;
    *) usage; exit 1 ;;
esac
