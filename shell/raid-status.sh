#!/bin/bash
# raid-status.sh — summarize active mdadm RAID arrays and their configuration

echo "=== RAID Arrays Summary ==="
echo

# Check if /proc/mdstat exists and show basic info
if [ -f /proc/mdstat ]; then
    echo "[/proc/mdstat]"
    cat /proc/mdstat
    echo
else
    echo "No /proc/mdstat file found (mdadm may not be installed or loaded)."
    exit 1
fi

# List all arrays detected by mdadm
arrays=$(grep ^md /proc/mdstat | awk '{print $1}')

if [ -z "$arrays" ]; then
    echo "No active RAID arrays detected."
    exit 0
fi

for array in $arrays; do
    echo "=== Details for /dev/$array ==="
    sudo mdadm --detail /dev/$array | egrep "Raid Level|State|Active Devices|Working Devices|Failed Devices|Spare Devices|UUID|Device Role|/dev/"
    echo
done

# Optional: show array definitions from mdadm.conf
if [ -f /etc/mdadm/mdadm.conf ]; then
    echo "=== Entries in /etc/mdadm/mdadm.conf ==="
    grep ^ARRAY /etc/mdadm/mdadm.conf
fi
