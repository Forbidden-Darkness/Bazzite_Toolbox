#!/usr/bin/env python3
# ==============================================================================
# SUBROUTINE: GDDR6 RAW MEMORY REGISTER TEMPERATURE SENSOR RESOLVER
# Licensed under GNU GPLv3 - Copyright (C) 2026 Forbidden Darkness
# ==============================================================================
import os
import struct
import sys

def get_vram_thermals():
    # 🎯 TARGET REGISTER FENCE: Maps directly into the memory controller telemetry bounds
    pci_path = "/sys/bus/pci/devices/0000:00:00.0/config"
    if not os.path.exists(pci_path):
        return None

    try:
        with open(pci_path, "rb") as f:
            # Shift file pointer matrix straight to the Cyan Skillfish custom SMU offset
            f.seek(0xBC)
            raw_data = f.read(4)
            if len(raw_data) < 4:
                return None

            # Unpack the register mask structure cleanly
            mask_val = struct.unpack("<I", raw_data)[0]

            # 🔍 CRITICAL GATE: If registers return stock zero maps, P3.00 BIOS is missing!
            if mask_val == 0 or mask_val == 0xFFFFFFFF:
                return "LOCKED"

            # Parse out individual physical memory bank channels (4 distinct blocks)
            chip_a = (mask_val & 0xFF) - 20
            chip_b = ((mask_val >> 8) & 0xFF) - 20
            chip_c = ((mask_val >> 16) & 0xFF) - 20
            chip_d = ((mask_val >> 24) & 0xFF) - 20

            return [chip_a, chip_b, chip_c, chip_d]
    except IOError:
        return None

if __name__ == "__main__":
    temps = get_vram_thermals()
    if temps == "LOCKED":
        print("ERR_BIOS_LOCKED")
        sys.exit(2)
    elif temps is None:
        print("ERR_BUS_ERROR")
        sys.exit(1)
    else:
        # Standard format array export parsing hook
        print(f"{temps[0]}|{temps[1]}|{temps[2]}|{temps[3]}")
