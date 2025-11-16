#!/usr/bin/env bash
# create-raid1.sh — Safely create a new RAID-1 array from two disks
# Usage: sudo ./create-raid1.sh /dev/sdX /dev/sdY [LABEL] [MOUNTPOINT]
# Example: sudo ./create-raid1.sh /dev/sdd /dev/sde data2 /mnt/md1
#
# - Creates GPT partitions on both disks
# - Creates /dev/md<N> as RAID1 with internal bitmap
# - Makes ext4 filesystem with optional LABEL (default: data_raid1)
# - Adds mdadm entry and /etc/fstab line
# - Mounts the new filesystem at MOUNTPOINT (default: /mnt/<LABEL>)
# What it does, step by step:
#  •  Wipes old signatures on the two disks (after you type YES to confirm)
#  •  Partitions both as GPT with a single full-size RAID partition
#  •  Creates a new /dev/mdN RAID-1 array (chooses the next free md number)
#  •  Adds an internal bitmap for faster rebuilds
#  •  Formats as ext4 with the label you provide (default data_raid1)
#  •  Mounts it and appends a persistent entry to /etc/fstab
#  •  Appends the array definition to /etc/mdadm/mdadm.conf and runs update-initramfs
#  •  Prints a summary and shows RAID/space status


set -euo pipefail

RED=$'\e[31m'; GRN=$'\e[32m'; YLW=$'\e[33m'; BLU=$'\e[34m'; RST=$'\e[0m'

die() { echo "${RED}Error:${RST} $*" >&2; exit 1; }

need_root() { [[ $EUID -eq 0 ]] || die "Please run as root (use sudo)."; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1 (install via apt)"
}

confirm() {
  local prompt=$1
  read -r -p "$prompt [type YES to continue]: " ans
  [[ "$ans" == "YES" ]]
}

next_md_name() {
  # Find next free /dev/mdN (prefers md1 if only md0 exists)
  local n=0
  while [[ -e "/dev/md${n}" ]]; do n=$((n+1)); done
  echo "/dev/md${n}"
}

append_unique_line() {
  # Append a line to a file only if an equivalent line is not already present
  local line="$1" file="$2"
  grep -Fxq "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

main() {
  need_root
  need_cmd lsblk
  need_cmd mdadm
  need_cmd parted
  need_cmd blkid
  need_cmd sed
  need_cmd awk

  if [[ $# -lt 2 ]]; then
    cat <<USAGE
${YLW}Usage:${RST} sudo $0 /dev/sdX /dev/sdY [LABEL] [MOUNTPOINT]
  Example: sudo $0 /dev/sdd /dev/sde data2 /mnt/md1
USAGE
    exit 1
  fi

  local DISK_A="$1"
  local DISK_B="$2"
  local FS_LABEL="${3:-data_raid1}"
  local MOUNTPOINT="${4:-/mnt/${FS_LABEL}}"

  [[ -b "$DISK_A" ]] || die "Not a block device: $DISK_A"
  [[ -b "$DISK_B" ]] || die "Not a block device: $DISK_B"
  [[ "$DISK_A" != "$DISK_B" ]] || die "Disks must be different."

  echo "${BLU}Disks:${RST} $DISK_A and $DISK_B"
  lsblk -o NAME,SIZE,TYPE,MODEL,SERIAL "$DISK_A" "$DISK_B" || true
  echo

  # Safety: ensure these are whole disks (not partitions)
  [[ "$DISK_A" =~ ^/dev/[a-z]+$|^/dev/nvme[0-9]+n[0-9]+$ ]] || echo "${YLW}Warning:${RST} $DISK_A looks like a partition."
  [[ "$DISK_B" =~ ^/dev/[a-z]+$|^/dev/nvme[0-9]+n[0-9]+$ ]] || echo "${YLW}Warning:${RST} $DISK_B looks like a partition."

  echo "${YLW}WARNING:${RST} This will ${RED}erase${RST} partition tables and any data on ${DISK_A} and ${DISK_B}."
  confirm "Continue and wipe existing signatures?" || die "Aborted by user."

  # Try to unmount anything on these disks
  umount "${DISK_A}"* 2>/dev/null || true
  umount "${DISK_B}"* 2>/dev/null || true

  # Wipe old signatures & md superblocks (best-effort)
  wipefs -a "$DISK_A" || true
  wipefs -a "$DISK_B" || true
  mdadm --zero-superblock "$DISK_A" 2>/dev/null || true
  mdadm --zero-superblock "$DISK_B" 2>/dev/null || true

  # Partition: GPT + single full-size partition with raid flag
  for d in "$DISK_A" "$DISK_B"; do
    parted -s "$d" mklabel gpt
    parted -s "$d" mkpart primary 1MiB 100%
    # Set 'raid' flag on partition 1 if supported (SATA/HDD typical)
    parted -s "$d" set 1 raid on || true
  done

  # Determine partition names (handle nvme naming)
  partA="${DISK_A}1"
  partB="${DISK_B}1"
  [[ -b "$partA" ]] || partA="${DISK_A}p1"
  [[ -b "$partB" ]] || partB="${DISK_B}p1"
  [[ -b "$partA" && -b "$partB" ]] || die "Could not find created partitions ($partA, $partB)."

  echo "${GRN}Partitions created:${RST} $partA and $partB"
  lsblk -o NAME,SIZE,TYPE,PARTTYPENAME "$partA" "$partB" || true
  echo

  # Create the RAID-1 array
  MD_DEV="$(next_md_name)"
  echo "${BLU}Creating RAID-1 array at ${MD_DEV} ...${RST}"
  mdadm --create --verbose "$MD_DEV" --level=1 --raid-devices=2 "$partA" "$partB"

  # Optional: add internal bitmap to speed rebuilds
  mdadm --grow --bitmap=internal "$MD_DEV" || true

  echo
  echo "${BLU}Sync status:${RST} (press Ctrl+C to exit watch)"
  (command -v watch >/dev/null 2>&1 && watch -n 3 cat /proc/mdstat) || cat /proc/mdstat
  echo

  # Make filesystem (ext4 by default)
  echo "${BLU}Creating ext4 filesystem with label '${FS_LABEL}' ...${RST}"
  mkfs.ext4 -L "${FS_LABEL}" "$MD_DEV"

  # Create mountpoint & mount
  mkdir -p "${MOUNTPOINT}"
  echo "${BLU}Mounting ${MD_DEV} at ${MOUNTPOINT} ...${RST}"
  mount "$MD_DEV" "$MOUNTPOINT"

  # Ensure mdadm config contains the array (idempotent-ish)
  echo "${BLU}Updating mdadm configuration...${RST}"
  md_line="$(mdadm --detail --scan | awk -v md="$MD_DEV" '$2==md {print}')"
  if [[ -z "$md_line" ]]; then
    md_line="$(mdadm --detail --scan | head -n1)"
  fi
  [[ -n "$md_line" ]] || die "Could not get mdadm scan line."
  mkdir -p /etc/mdadm
  touch /etc/mdadm/mdadm.conf
  append_unique_line "$md_line" /etc/mdadm/mdadm.conf
  update-initramfs -u || true

  # Add fstab entry
  UUID="$(blkid -s UUID -o value "$MD_DEV")"
  [[ -n "$UUID" ]] || die "Could not determine filesystem UUID."
  fstab_line="UUID=${UUID}  ${MOUNTPOINT}  ext4  defaults,noatime  0  2"
  echo "${BLU}Adding to /etc/fstab:${RST} ${fstab_line}"
  append_unique_line "$fstab_line" /etc/fstab

  # Test fstab
  echo "${BLU}Testing /etc/fstab by re-mounting...${RST}"
  umount "$MOUNTPOINT"
  mount -a

  echo
  echo "${GRN}All done!${RST} Summary:"
  echo "  RAID device : $MD_DEV"
  echo "  Members     : $partA, $partB"
  echo "  Level       : raid1"
  echo "  Filesystem  : ext4 (label='${FS_LABEL}')"
  echo "  Mount point : ${MOUNTPOINT}"
  echo
  mdadm --detail "$MD_DEV" || true
  df -h | grep -E "Filesystem|${MOUNTPOINT}" || true
}

main "$@"

