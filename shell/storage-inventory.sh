#!/usr/bin/env bash
# storage-inventory.sh — Inspect storage hardware, connected disks, and estimate SATA ports.

set -euo pipefail

need_cmd() { command -v "$1" >/dev/null 2>&1 || echo "MISSING: $1"; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

echo "=== STORAGE INVENTORY (run with sudo for best results) ==="
echo

# 0) Quick install tips (not auto-installing)
missing=()
for c in lsblk lspci lshw dmidecode dmesg awk sed grep; do
  if ! have_cmd "$c"; then missing+=("$c"); fi
done
if ((${#missing[@]})); then
  echo "Note: You’re missing some tools: ${missing[*]}"
  echo "On Debian/Ubuntu/Mint, you can install common tools with:"
  echo "  sudo apt update && sudo apt install pciutils usbutils lshw dmidecode util-linux"
  echo
fi

# 1) Motherboard (for definitive slot count, look this up online)
echo "— Motherboard / Baseboard —"
if have_cmd dmidecode; then
  sudo dmidecode -t baseboard 2>/dev/null | awk '
    /^Base Board Information/ {show=1; print; next}
    show && NF {print}
    show && /^$/ {show=0}
  '
else
  echo "dmidecode not found."
fi
echo

# 2) Storage controllers on PCIe (SATA/NVMe/RAID HBAs)
echo "— Storage Controllers (PCI) —"
if have_cmd lspci; then
  lspci | grep -iE "sata|ahci|raid|nvme|storage" || echo "No storage controllers found."
else
  echo "lspci not found."
fi
echo

# 3) Connected disks overview
echo "— Connected Disks (lsblk) —"
if have_cmd lsblk; then
  lsblk -o NAME,TRAN,TYPE,SIZE,MODEL,SERIAL,MOUNTPOINT -e7
else
  echo "lsblk not found."
fi
echo

# 4) Detailed storage topology
echo "— lshw (storage + disk classes) —"
if have_cmd lshw; then
  sudo lshw -short -class storage -class disk 2>/dev/null || echo "lshw could not list devices."
else
  echo "lshw not found."
fi
echo

# 5) Kernel view of md/RAID (if in use)
if [[ -r /proc/mdstat ]]; then
  echo "— /proc/mdstat —"
  cat /proc/mdstat
  echo
fi

# 6) Estimate SATA port count via kernel messages (best-effort heuristic)
echo "— SATA Link Status (heuristic) —"
if have_cmd dmesg; then
  # Grab lines like: "ata5: SATA link up 6.0 Gbps (SStatus ...)" or "ata4: SATA link down ..."
  mapfile -t ata_lines < <(dmesg | grep -iE "ata[0-9]+: SATA link (up|down)" || true)
  if ((${#ata_lines[@]})); then
    printf "%s\n" "${ata_lines[@]}"
    # Extract port indices and estimate max
    max_port=$(printf "%s\n" "${ata_lines[@]}" | grep -oE 'ata[0-9]+' | sed 's/ata//' | sort -n | tail -1)
    up_count=$(printf "%s\n" "${ata_lines[@]}" | grep -ci "link up" || true)
    down_count=$(printf "%s\n" "${ata_lines[@]}" | grep -ci "link down" || true)
    echo
    echo "Estimated total SATA ports seen by kernel: $max_port"
    echo "Links up:   $up_count"
    echo "Links down: $down_count"
    echo "(If you see ata1..ata6, your chipset/BIOS likely exposes 6 SATA ports.)"
  else
    echo "No clear SATA link messages found in dmesg (not unusual on some kernels/chipsets)."
  fi
else
  echo "dmesg not found."
fi
echo

# 7) NVMe devices and controllers
echo "— NVMe Devices —"
if have_cmd lsblk; then
  nvmes=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk" && $1 ~ /^nvme/ {print $1}')
  if [[ -n "${nvmes:-}" ]]; then
    for n in $nvmes; do
      echo "NVMe: /dev/$n"
      # nvme cli (optional) gives more details
      if command -v nvme >/dev/null 2>&1; then
        sudo nvme list | grep -i "$n" || true
      else
        lsblk -o NAME,SIZE,MODEL,SERIAL,MOUNTPOINT "/dev/$n"
      fi
    done
    echo "(Exact NVMe slot count usually requires motherboard manual; Linux shows what’s populated.)"
  else
    echo "No NVMe disks detected."
  fi
else
  echo "lsblk not found."
fi
echo

echo "=== NOTES ==="
echo "* Linux can list what’s connected and what the chipset exposes; it cannot definitively tell the physical number of ports/slots on your motherboard."
echo "* For an authoritative answer, use the motherboard model above to check the vendor’s spec sheet (e.g., \"ModelName SATA ports\")."
echo "* HBA/RAID cards add ports that won’t match the baseboard’s count."
