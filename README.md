## Bazzite Toolbox Installation & Technical Reference Guide
A hardware-level automation utility and command-line management terminal custom-tailored for systems running Bazzite 43 and 44 Deck distributions on specialized AMD BC-250 architecture layouts (PlayStation 5 APU "Cyan Skillfish" platforms). This toolbox bridges low-level POSIX firmware compilation with transactional operating system parameters to securely unlock hardware registers, safely tune memory partitions, manage overclock interfaces, and preserve core system stability configurations.

## ⚠️ Technical Disclaimer & Risk Acknowledgement
This repository contains a personal script and configuration toolkit developed for optimization, research, and educational use on specialized hardware layout arrays. Modifying volatile hardware NVRAM registers, low-level silicon configuration maps, system voltages, and factory memory allocations carries inherent technical risk.
By executing this utility, you acknowledge that you are doing so entirely at your own risk. The developer assumes no responsibility or liability for system instability, data loss, kernel panics, hardware exhaustion, or component degradation resulting from structural overrides applied by this toolbox. Always maintain verified system backups and monitor chip thermal thresholds during deployment phases.

------------------------------
## 🚀 Installation & Setup
Clone the repository, configure executable permissions, and initialize the primary setup script.

```bash
mkdir -p "$HOME/Applications" && cd "$HOME/Applications" && if [ -d "Bazzite_Toolbox" ]; then read -p "Bazzite_Toolbox already exists. Overwrite? (y/N): " ans; [[ "$ans" =~ ^[Yy]$ ]] && rm -rf Bazzite_Toolbox || exit 1; fi && git clone https://github.com/Forbidden-Darkness/Bazzite_Toolbox.git && cd Bazzite_Toolbox/ && chmod +x *.sh && sudo ./start.sh
```

------------------------------
## 🛠️ Configuration Management

## Add System Shortcut
Integrate the Bazzite Toolbox shortcut into the System & Utilities directory of your desktop environment's application menu.

```bash
cd /var/home/bsystem/Applications/Bazzite_Toolbox && sudo ./start.sh --install-shortcut && exit
```

## Remove System Shortcut
Remove the application shortcut from the System & Utilities menu.
Note: This command triggers an automatic system reboot to apply changes and refresh the desktop environment configuration.

```bash
cd /var/home/bsystem/Applications/Bazzite_Toolbox/ && sudo bash -c "./start.sh --remove-shortcut" ; sudo systemctl reboot
```
------------------------------
## 📟 Technical Architecture Overview
The toolbox acts as an intelligent abstraction layer over Bazzite's immutable, transaction-based rpm-ostree image structure. Rather than introducing transient or volatile overrides, it manipulates configurations using a twin-injection design layout, altering kernel parameters through native boot entries while concurrently staging modular configuration rules for hardware compilation trees.
```text
                ┌──────────────────────────────────────┐
                │       Bazzite Toolkit Terminal       │
                └──────────────────┬───────────────────┘
                                   │
         ┌─────────────────────────┴─────────────────────────┐
         ▼                                                   ▼
┌─────────────────────────────────┐                 ┌─────────────────────────────────┐
│     Hardware Register Tuning    │                 │   Operating System Base Layer   │
├─────────────────────────────────┤                 ├─────────────────────────────────┤
│ • Native POSIX C NVRAM Compiler │                 │ • rpm-ostree kargs Automation   │
│ • Local CMOS UMA Table Writes   │                 │ • TTM Memory Page Limits        │
│ • Real-time UMR GFX Bitmaps     │                 │ • Dedicated GTT Size Cushion    │
│ • SMU Overclock Daemon Hooks    │                 │ • Protected quiet / rhgb Boot   │
└─────────────────────────────────┘                 └─────────────────────────────────┘
```

------------------------------

## 💎 Core Optimization Engine Features

## 1. Unified RAM/VRAM Hardware Splitting (Bazzite 43 & 44 Deck Specifics)

* POSIX C NVRAM Engine: To ensure absolute offline resilience for users on un-layered platforms, the toolbox features a localized compiler driver routine that compiles an integrated, pure standard C module (main.c) utilizing standard POSIX headers. This prevents compilation errors derived from missing C++ standard library structures on immutable OS configurations.
* CMOS Memory Reallocation: Interrogates low-level system registers via /dev/nvram to securely alter volatile CMOS banks on cold boot sequences.
* Mathematical Page Mappings: Programmatically maps precise system memory sizes directly to the Linux Kernel Translation Table Manager (ttm.pages_limit and ttm.page_pool_size), scaling from maximum dynamic AI inference layers (~14.75GB GPU dynamic heap) up to traditional computing partitions.
* Graphics translation Table Alignment: Pairs every page allocation profile with an exact corresponding hardware translation cushion via amdgpu.gttsize. This prevents the amdgpu driver from choking under high VRAM loads, successfully mitigating out-of-memory driver starvation and system kernel panics.
* Boot-Loop Guard: Hardcoded memory matrices explicitly exclude the volatile 2GB allocation footprint, shielding non-Linux users against the native vendor hardware driver flaw that results in an unrecoverable system black screen on startup.
* Kernel Panic Removal Safety Gate: When executing a configuration rollback to stock defaults, the toolbox triggers an active hardware guard that forces the underlying motherboard CMOS registers back to a safe factory 8GB baseline allocation layer prior to wiping the kernel parameters, preventing immediate display server initialization crashes on the subsequent boot.

## 2. High-Contrast Silicon Compute Unit Harvesting Matrix

* DRM Pipeline Interrogation: Utilizes direct low-level binding calls against the native graphic runtime library (libdrm_amdgpu.so.1) to open the graphic engine render nodes (/dev/dri/renderD128) and systematically decode underlying platform structure fields.
* Real-time Asynchronous Mapping: Reads the raw mathematical hardware configuration matrix values to dynamically track active Compute Units (CUs), programmatically tracking uniform vs. harvested variations across Shader Engines (SE) and Shader Arrays (SH).
* Lottery Identification Script: Evaluates register bitmasks to determine if the host silicon is a 40/40 CU lottery winner, automatically outputting dynamic template parameter recommendations to cleanly mask layout disruptions and rebase active cores up to their maximum performance boundaries.

## 3. Isolated Performance Suite Customization (Blue & Red Pills)

This toolkit completely overhauls Bazzite's virtual memory subsystem, introducing an ultra-dense, optimized **ZSWAP Core Matrix** specifically engineered to stabilize aggressive hardware splits.

* **The Physical RAM Bottleneck:** Operating on an aggressive enthusiast layout split (**7GB System RAM / 9GB VRAM**) leaves an incredibly tight 7GB ceiling for background system tasks and Proton containers. Modern AAA titles easily request 12GB+ of system memory workspace.
* **The ZSTD & Z3fold Compression Edge:** Rather than utilizing unoptimized, low-ratio compression fallbacks, the toolbox forcefully injects `zswap.compressor=zstd` and `zswap.zpool=z3fold` into the system boot entries. ZSTD provides extreme data density for complex gaming textures, while the Z3fold allocator allows the kernel to pack *three* compressed pages into a single physical memory frame instead of the standard two—increasing caching space efficiency by up to 50%!
* **Hardened Cache Ceiling Allocation:** By expanding `zswap.max_pool_percent=40`, the kernel allows the compressed ZSWAP memory cache to safely claim up to **40% of physical RAM**. Coupled with an unfragmented 16GB (Blue Pill) or 32GB (Red Pill) continuous BTRFS storage swapfile, the architecture provides a massive, high-speed fallback buffer. This completely eliminates disk-thrashing frame drops and keeps your camera pans buttery smooth right at your **60 FPS target**!

## 4. Bazzite Core Graphical Splash Screen Shield

* Deployment Interlock Security: Atomic file writes and structural arguments updates traditionally clear default unanchored parameters on image re-serializations. This toolbox implements an isolated Visual Recovery Pass during compilation steps, dynamically ensuring quiet and rhgb boot arguments are forced back down into the transactional tree layout. This permanently prevents the system from accidentally dropping its graphical animation and revealing raw console boot logs on startup.

## 5. Advanced Subsystem & Sensor Controls

* Xone Driver Integration: Seamlessly triggers localized module layering pipelines to hook and mount the official Microsoft Xbox Wireless Adapter driver stack (xone and kmod-xone), instantly enabling native wireless accessory functionality.
* Fan Control & ACPI Voltage Overrides: Interrogates firmware registers to mount low-level sensor drivers (nct6687), exposing full PWM fan controller access to background daemon controllers (CoolerControl). It handles software-level ACPI architecture injection targets seamlessly, loading custom tables via early boot initrd overrides to safely stabilize clock speeds.

------------------------------

## 🧬 Memory Page Calculation Reference Matrix
The Linux Translation Table Manager (`ttm`) tracks memory ceilings explicitly using system memory pages, where **1 Page = 4096 Bytes (4KB)**. The toolbox programmatically translates your choices into precise values to prevent driver allocation truncation collisions:

* Profile 1: Extreme VRAM Split
* Kernel Argument String: ttm.pages_limit=1572864 | amdgpu.gttsize=10240
   * Mathematical Formula: 1,572,864 × 4096 ÷ 1024³ = 6.0 GB assigned to the Operating System Pool.
   * Resulting Hardware Profile: ~6GB System RAM available for Bazzite / ~10GB Dedicated VRAM reserved for the GPU.
* Profile 2: High VRAM Split
* Kernel Argument String: ttm.pages_limit=1835008 | amdgpu.gttsize=9216
   * Mathematical Formula: 1,835,008 × 4096 ÷ 1024³ = 7.0 GB assigned to the Operating System Pool.
   * Resulting Hardware Profile: ~7GB System RAM available for Bazzite / ~9GB Dedicated VRAM reserved for the GPU.
* Profile 3: Stock Layout Split
* Kernel Argument String: ttm.pages_limit=2097152 | amdgpu.gttsize=8192
   * Mathematical Formula: 2,097,152 × 4096 ÷ 1024³ = 8.0 GB assigned to the Operating System Pool.
   * Resulting Hardware Profile: ~8GB System RAM available for Bazzite / ~8GB Dedicated VRAM (Stock Blueprint Configuration).
* Profile 4: Balanced Allocation
* Kernel Argument String: ttm.pages_limit=2621440 | amdgpu.gttsize=6144
   * Mathematical Formula: 2,621,440 × 4096 ÷ 1024³ = 10.0 GB assigned to the Operating System Pool.
   * Resulting Hardware Profile: ~10GB System RAM available for Bazzite / ~6GB Dedicated VRAM. (Mitigates GameScope Framebuffer Crashes).
* Profile 5: Entry VRAM Split
* Kernel Argument String: ttm.pages_limit=3145728 | amdgpu.gttsize=4096
   * Mathematical Formula: 3,145,728 × 4096 ÷ 1024³ = 12.0 GB assigned to the Operating System Pool.
   * Resulting Hardware Profile: ~12GB System RAM available for Bazzite / ~4GB Dedicated VRAM.
* Profile 6: Native 512MB Split
* Kernel Argument String: ttm.pages_limit=3932160 | amdgpu.gttsize=15104
   * Mathematical Formula: 3,932,160 × 4096 ÷ 1024³ = 15.0 GB assigned to the Operating System Pool.
   * Resulting Hardware Profile: Maximum System RAM available for Bazzite / ~512MB Dedicated Base GPU Buffer (Recommended for local LLM AI Workloads).
   
------------------------------

### 📊 RAM/VRAM Allocation Performance Matrix

| Allocation Profile Index | Hardware Profile Mapping | Gaming Suitability | Targeted Use Case Performance |
| :--- | :--- | :--- | :--- |
| **1) Extreme Split** | ~6GB System RAM / ~10GB VRAM | **Specialized** | Best for running VRAM-heavy emulator setups or heavy game textures, but leaves system memory very tight. |
| **2) High Split** | ~7GB System RAM / ~9GB VRAM | **Good** | Provides a solid hardware balance mimicking modern console processing architectures. |
| **3) Stock Split** | ~8GB System RAM / ~8GB VRAM | **Stable Baseline** | The default factory standard. Reliable across general workflows but lacks a performance edge. |
| **4) Balanced Allocation** | ~10GB System RAM / ~6GB VRAM | **🥇 Highly Recommended** | Fixes GameScope framebuffer rendering crashes. Gives the OS plenty of breathing room. |
| **5) Entry Split** | ~12GB System RAM / ~4GB VRAM | **Excellent** | Perfect baseline profile for standard computing workloads and regular 1080p gaming titles. |
| **6) Native 512MB Split** | Max System RAM / ~512MB VRAM | **❌ Not Recommended** | Specifically configured for local AI inference model parsing and heavy development sets. |

------------------------------

## 🗺️ Bazzite 43 vs. Bazzite 44 Core Divergence Pathing Matrix
Bazzite 43 and 44 migrated across distinct generational shifts of the Fedora base layer. This toolbox accounts for these underlying changes automatically to protect system operations from breaking:

| Architectural System Component | Bazzite 43 Environment Blueprint (Fedora 40 Base Layer) | Bazzite 44 Deck Environment Blueprint (Fedora 41 Base Layer) | Toolbox Native Resolution Method |
|---|---|---|---|
| Boot Loader Entry Storage | Maintained static file blocks via /boot/efi/EFI/fedora/grub.cfg. | Migrated to the modernized Boot Loader Specification layout inside /boot/loader/entries/. | Unified System Call: Interrogates target environments and safely wraps commands with a dual fallback call: ujust regenerate-grub \|\| sudo grub2-mkconfig. |
| Power Daemon Package Target | Packaged and cataloged system level clock utilities via kernel-tools. | Segregated core power controllers into a specialized, standalone cpupower package file structure. | Silent Search Interlock: Evaluates localized package indexes using rpm-ostree search before forcing installs, blocking missing package layer breaks. |
| Compiler Toolchain Limits | Handled standard memory references and linker allocations via early C++ header formats. | Enforced strict compilation optimization checking that explicitly drops unbound C++ library includes. | POSIX C Offline Failback: Strips all C++ dependencies out of the script's local memory backup. Writes out a pure C engine (main.c) compiled cleanly by standard gcc. |

------------------------------

## ❓ Frequently Asked Questions (FAQ)

### What is the functional difference between the "Blue Pill" and "Red Pill" configurations?
The distinct suite selections alter system memory paging constraints based on physical storage capacity while utilizing an identical ultra-dense ZSWAP architecture:
* **Blue Pill (16GB Optimization Profile):** This mode provisions a 16GB unfragmented BTRFS swapfile backing store on your storage volume. It is meticulously configured for stock memory layouts (such as 12GB System / 4GB VRAM splits) to provide a balanced memory cushion without allocating massive background storage tables.
* **Red Pill (32GB Optimization Profile):** This profile provisions a heavy-duty 32GB unfragmented BTRFS swapfile backing store on your storage volume. It is custom-tailored specifically for extreme enthusiast layouts (such as the 7GB System / 9GB VRAM High Split) to deliver a massive virtual performance cushion, completely absorbing vast computational pages when running dense dynamic memory configurations.

### Why is an explicit compressed RAM cache required for custom VRAM splits?
The AMD BC-250 chip operates on a hard fixed 16GB total pool of unified GDDR6 memory. Dropping the default operating system allocation parameters down to narrow thresholds (leaving only 6GB or 7GB under the Extreme and High splits) leaves inadequate space for standard Bazzite game launchers and runtime desktop containers. By displacing volatile system data pools into an unbottlenecked, ultra-fast LZ4/ZSTD ZSWAP memory cushion rather than letting them hit a slow, fragmented physical drive swapfile without optimized compression parameters, your architecture completely mitigates application crashes and maintains high computing throughput despite physical RAM restrictions.

### Why did option 6 (Native 512MB Split) throw a kernel panic in early manual rollbacks?
Without companion translation properties structured into the boot arguments layer, the native `amdgpu` driver initializations map translation thresholds relative to baseline visible memory blocks. When the Linux kernel handshakes a 512MB window under heavy display compositors without a hard-coded memory translation fence table (`amdgpu.gttsize`), allocation parameters overflow instantly, triggering a critical hardware register fault. The updated toolbox completely isolates this quirk by automatically re-indexing CMOS NVRAM tables back to an 8GB layout buffer *before* cleaning out module drivers.

### Is this toolkit compatible with transaction-based atomic file updates?
Yes. Every configuration pipeline maps changes dynamically via standard systemd overrides, local modprobe target rules, and transaction-safe `rpm-ostree kargs` calls. Running automated toolbox operations handles configuration migrations safely without disrupting Bazzite's background image delivery architecture.

# Contributing to Bazzite Toolbox

Thank you for your interest in optimizing and bulletproofing the Bazzite Toolbox. This project is a personal optimization terminal opened up to the wider community. To maintain data isolation, syntactic precision, and absolute hardware execution safety across **Bazzite 43 and 44 Deck** branches, all code modifications must align with strict low-level compilation guidelines.

## 🛠️ Staging Environment Rules

### 1. Immutability Preservation
* **No Host Alterations:** All driver inclusions, kernel logic tweaks, and subsystem overrides must operate seamlessly within the Fedora Atomic blueprint interface using standard transaction-safe tools (`rpm-ostree kargs`, `ujust`, or local rule files inside `/etc/modprobe.d/` and `/etc/sysctl.d/`). Do not submit hooks that assume write access to standard root paths (`/usr`, `/bin`, or `/lib`).

### 2. POSIX Compliance & Header Avoidance
* **Pure C Memory Hooks:** Any downstream changes made to internal compilation engines or tool architectures (`bc250_memcfg` or matching hardware tracking frameworks) must be structured in pure standard C utilizing POSIX compliance patterns (`#include <stdio.h>`).
* **Zero Dependency Builds:** Bazzite images do not ship with full C++ development kit libraries or standard runtime template caches natively layered. Offline scripts must map calculations using basic structural arrays (`argv[]`) to guarantee a successful compilation run right out of script memory without forcing package dependencies onto the customer node.

### 3. Separation of Image Layer Transactions
* **Avoid Race Conditions:** When modifying multiple operational fields at the same time, split the commands into distinct terminal logic loops. Never bundle low-level memory reallocations (`ttm.pages_limit`) and display variables (`quiet rhgb`) into a shared `rpm-ostree` string wrapper; this causes Bazzite's atomic layer parser to choke and strip visual components from the active boot tree entries.

## 📥 Submission Lifecycle (Pull Requests)

1. **Isolate Your Target Fields:** Fork the repository and decouple your changes onto a specific feature branch tracking current deployment structures.
2. **Validate Arithmetic Layout Matrices:** Confirm all custom mathematical page modifications increment cleanly by steps of `262144` or `524288` pages to keep byte blocks cleanly aligned on x86 architectures without decimal truncations.
3. **Audit Execution Path Logs:** Verify that unexpected network dropouts or repository structural shifts cleanly fall back to internal script storage without dumping non-Linux users onto broken console lines or raw script syntax errors.
4. **Submit a Detailed Briefing:** Outline your hardware test environment results (Bazzite image release build tag, memory profile results, temperature limits) directly within your Pull Request description file layout.

------------------------------

## 📂 Repository File Tree Reference

The toolbox utilizes a unified flat-directory footprint mapped straight out the repository base workspace layer:

```text
Bazzite_Toolbox/
├── Overclock/
│   ├── Overclock-Live-Manager.sh     <-- Dedicated SMU CPU Overclock script tool
│   └── bc250-cu-live-manager.conf     <-- Compute Unit live manager data map
├── Wake_on_LAN/
│   ├── Wake-on-LAN-Manager.sh        <-- Wake-on-LAN port/adapter configuration
│   └── Red-Pill-Blue-Pill.wav         <-- Permission-insulated PipeWire background audio
├── LICENSE                            <-- GNU General Public License v3.0 text logs
├── README.md                          <-- Primary master optimization reference manual
├── index.html                         <-- Compute Unit map matrix HTML dashboard panel
└── start.sh                           <-- Toolkit dashboard UI & main controller block
```

## 🕹️ Game Launcher Configuration Guide

To activate the advanced vector math loops and force-initialize the upscaler proxy bridge on your AMD BC-250 architecture, find your game launcher from the list below and apply the required environment overrides.

### 🎮 1. Steam (Native & Non-Steam Shortcuts)
1. Open your Steam Library, right-click your game, and select **Properties**.
2. Stay on the **General** tab and scroll down to the **Launch Options** field at the bottom.
3. Paste the following string exactly into the launch box:
   ```text
   WINEDLLOVERRIDES="dxgi=n,b" %command%
   ```

---

### 📦 2. Heroic Games Launcher (Epic, GOG, Amazon)
1. Click on your game card cover inside Heroic and open its **Settings (Gear Icon)**.
2. Navigate down to the **Environment Variables** tab menu section.
3. Click **Add Variable** and input the following configuration parameters:

| Environment Variable Key | Target Assignment Value |
| :--- | :--- |
| `WINEDLLOVERRIDES` | `dxgi=n,b` |

---

### 🦊 3. Lutris
1. Right-click your game tile card and select **Configure**.
2. Navigate over to the **System options** tab panel grid header at the top.
3. Scroll down to the **Environment variables** entry grid panel.
4. Click the **Add** button and input your strings character-for-character:

| Variable Parameter | Assigned Configuration |
| :--- | :--- |
| `WINEDLLOVERRIDES` | `dxgi=n,b` |

---

### 🍾 4. Bottles
1. Open your targeted game execution Bottle environment wrapper space.
2. Head straight into the **Environment Variables** component menu section page.
3. Click the **+ New Variable** button row and append your validation tokens:

| Variable Name Identifier | Local Value Property |
| :--- | :--- |
| `WINEDLLOVERRIDES` | `dxgi=n,b` |

---

### 💎 5. Prism Launcher (Minecraft & Java Injections)
1. Open Prism Launcher, select your active instance profile card, and click **Edit**.
2. Go into the **Environment** settings panel sub-tab configuration screen.
3. Click **Add** or append these keys directly into your instance runtime properties sheet:

| Variable Key Property | State Control Value |
| :--- | :--- |
| `WINEDLLOVERRIDES` | `dxgi=n,b` |

---

### 💎 6. Rare (Minimalist Epic Games Launcher alternative)
1. Select your target game inside Rare and click on its **Game Settings** cog.
2. Look for the **Environment Variables** text entry layout box.
3. Click add row and input:

| Key Name | Value |
| :--- | :--- |
| `WINEDLLOVERRIDES` | `dxgi=n,b` |

---

### 💾 7. Cartridge (Popular Linux Desktop Game Library Manager)
1. Open Cartridge, click your game card, and enter its **Edit Configuration** panel.
2. Scroll to the **Environment Overrides** panel block row.
3. Append your variable parameters into the database fields:

| Environment Key | State Value |
| :--- | :--- |
| `WINEDLLOVERRIDES` | `dxgi=n,b` |

---

### 💻 8. Raw Terminal Console Execution (CLI Proton/Wine Wrappers)
If you are executing your Windows games directly via an isolated command line terminal loop (such as `umugex`, `proton-call`, or native custom terminal shortcuts), format your running string by prefixing the execution call directly:
```bash
WINEDLLOVERRIDES="dxgi=n,b" proton run /path/to/game.exe
```

------------------------------

## 🎨 Game-Engine Specific Preset Optimizers

When deploying the upscaler framework, the toolkit allows you to select from three hand-tuned, hardware-level engine profiles designed to maximize performance and eliminate graphical artifacts on the AMD BC-250 chip.

### 🛡️ 1. Standard Profile (Baseline RDNA1 Setup)
* **Target Titles:** *Marvel's Spider-Man: Miles Morales*, *Cyberpunk 2077*, *The Witcher 3: Wild Hunt*, and the vast majority of general DX12/Vulkan titles.
* **The Problem It Fixes:** Standard games often try to load massive, un-optimized texture tables that choke a tight system memory pool. Furthermore, without an explicit configuration anchor, the upscaler framework can experience ghosting trails or severe motion blur behind fast-moving characters during quick camera pans.
* **The Fix:** Initializes the pure, lean RDNA1 processing matrix. It binds the core upscaler execution directly to your **7GB System / 9GB VRAM High Split layout**, forcing the engine to handle motion vectors dynamically. This eliminates ghosting artifacts entirely and delivers unbottlenecked frame pacing right to your **60 FPS target**!

---

### 🧟 2. Capcom RE Engine Profile
* **Target Titles:** *Resident Evil 4 Remake*, *Resident Evil Village (RE8)*, *Dead Rising Deluxe Remaster*, and *Kunitsu-Gami: Path of the Goddess*.
* **The Problem It Fixes:** When modern Capcom games run on custom hardware splits, the engine's internal shader memory addresses get severely truncated. On the BC-250, this results in horrific flashing mesh structures, broken/stretched player models, missing hair assets, or instant startup crashes back to the desktop.
* **The Fix:** Automatically injects `RestoreComputeRootSignature=true` into your configuration layout. This forces the translation layer to cleanly rebuild and stabilize the game's compute signatures, making Capcom games visually flawless and perfectly stable.

> [!NOTE]
> Use this preset exclusively for titles built on Capcom's RE Engine to prevent geometry breakdown and missing asset textures.

---

### 🎨 3. Anti-Flicker Color Profile
* **Target Titles:** Modern Unreal Engine titles and games with heavy post-processing overlays, such as *Brothers: A Tale of Two Sons Remake*, *Frostpunk 2*, or *Witchfire*.
* **The Problem It Fixes:** Many modern games render their post-processing layouts inside an isolated HDR/Linear color domain. When the upscaler hooks the rendering pass on an RDNA1 chip, it can trigger severe fullscreen flashing, strobe-like strobe artifacts during menus/dialog sequences, or completely broken sky textures.
* **The Fix:** Automatically writes `ColorResourceBarrier=4` and `NonLinearSRGBInput=true` into the configuration profiles. This forces the graphics engine to interpret color processing spaces non-linearly, entirely ironing out the strobe flicker and stabilizing high-contrast scenes.

> [!WARNING]
> If you experience violent screen flashing or menu flickering in any Unreal Engine title, run the toggle installer again and choose this preset to protect your eyes.

------------------------------
## Special Thanks to the following:

* **Development of Blue/Red Pill Script for Bazzite:** [@NexGen-3D](https://github.com/NexGen-3D-Printing/SteamMachine)
* **Development of cyan-skillfish-governor:** [@FilippoR](https://github.com/filippor/cyan-skillfish-governor)
* **Development of bc250-cu-live-manager:** [@WinnieLV](https://github.com/WinnieLV/bc250-cu-live-manager)
* **Development of CPU Overclocking Tools for AMD BC-250:** [@bc250-collective](https://github.com/bc250-collective/bc250_smu_oc)
* **Development of bc250_memcfg (CMOS BIOS Utility):** [@fanoush](https://github.com/fanoush/bc250_memcfg)
* **Development of BC250 FSR4 INT8 Re-Ordered Compilations:** [@daniel-h-0](https://github.com/daniel-h-0/bc250-fsr4-fork)
* **Development of Upstream OptiScaler Hook Proxy Core Layers:** [@optiscaler](https://github.com/optiscaler/OptiScaler)
* **Development of GFX1013 Async Compute Queue Firmware Patches:** [@DryhoppedIPA](https://github.com/DryhoppedIPA/bc250-gfx1013-fix)
