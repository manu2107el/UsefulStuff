#!/usr/bin/env bash

set -euo pipefail

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root." >&2
   exit 1
fi

# Check for required tools
for cmd in zpool lsblk grep awk; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd command not found." >&2
        exit 1
    fi
done

echo "=========================================="
echo "    ZFS Interactive Drive Replacement     "
echo "=========================================="
echo

# 1. Select ZFS Pool
pools=($(zpool list -H -o name))

if [[ ${#pools[@]} -eq 0 ]]; then
    echo "No active ZFS pools found."
    exit 1
fi

echo "Available ZFS Pools:"
select POOL in "${pools[@]}"; do
    if [[ -n "${POOL:-}" ]]; then
        break
    else
        echo "Invalid selection. Please choose a valid pool number."
    fi
done

echo
echo "Selected Pool: $POOL"
echo "------------------------------------------"
zpool status "$POOL"
echo "------------------------------------------"
echo

# 2. Select Old/Failed Device
echo "Enter the Device Name, GUID, or ID of the drive to replace from above."
echo "Examples: 1234567890123456789, sdc, or vdev name (e.g. UNAVAIL):"
read -rp "Old Device / GUID: " OLD_DEV

if [[ -z "$OLD_DEV" ]]; then
    echo "Error: Old device cannot be empty." >&2
    exit 1
fi

# 3. Scan system disks and inspect pool/FS usage
echo
echo "Scanning available system disks..."
echo "--------------------------------------------------------------------------------"

# Build a string of all active zpool configurations to match active pool drives
ALL_ZPOOL_STATUS=$(zpool status 2>/dev/null || true)

# Fetch all top-level disk drives (type 'disk'), excluding loop/rom devices
mapfile -t sys_disks < <(lsblk -d -n -o NAME,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINT -e 7,11 | sort)

disk_ids=()
display_labels=()

for line in "${sys_disks[@]}"; do
    dev_name=$(echo "$line" | awk '{print $1}')
    dev_size=$(echo "$line" | awk '{print $2}')
    dev_model=$(echo "$line" | awk '{print $3}')
    dev_fstype=$(echo "$line" | awk '{print $5}')
    dev_mount=$(echo "$line" | awk '{print $6}')

    # Find persistent disk ID for this device (/dev/disk/by-id/)
    by_id_name=$(ls -l /dev/disk/by-id/ 2>/dev/null | grep -v 'part' | grep -W "$dev_name$" | awk '{print $9}' | grep -E '^(ata|nvme|scsi|wwn)-' | head -n 1 || true)
    
    if [[ -z "$by_id_name" ]]; then
        continue
    fi

    # Determine usage status
    status_tag="[AVAILABLE / UNUSED]"
    
    # Check if drive or partition is part of a ZFS pool
    if echo "$ALL_ZPOOL_STATUS" | grep -q "$dev_name" || echo "$ALL_ZPOOL_STATUS" | grep -q "$by_id_name"; then
        # Extract matching pool name
        matched_pool=$(zpool list -H -o name | while read -r p; do zpool status "$p" | grep -E -q "$dev_name|$by_id_name" && echo "$p"; done | head -n 1)
        status_tag="[IN POOL: ${matched_pool:-unknown}]"
    elif [[ -n "$dev_fstype" && "$dev_fstype" != "null" ]]; then
        status_tag="[USED: $dev_fstype]"
    elif [[ -n "$dev_mount" && "$dev_mount" != "null" ]]; then
        status_tag="[MOUNTED: $dev_mount]"
    fi

    disk_ids+=("$by_id_name")
    display_labels+=("$by_id_name  |  Size: $dev_size  |  Model: $dev_model  |  Status: $status_tag")
done

if [[ ${#disk_ids[@]} -eq 0 ]]; then
    echo "Error: No candidate drives found in /dev/disk/by-id/." >&2
    exit 1
fi

echo "Select Replacement Disk:"
PS3="Select drive number: "
select CHOICE in "${display_labels[@]}"; do
    if [[ -n "${CHOICE:-}" ]]; then
        index=$(( REPLY - 1 ))
        NEW_DEV_NAME="${disk_ids[$index]}"
        NEW_DEV="/dev/disk/by-id/$NEW_DEV_NAME"
        SELECTED_INFO="${display_labels[$index]}"
        break
    else
        echo "Invalid selection. Choose a number from the list."
    fi
done

echo
echo "--------------------------------------------------------------------------------"
echo "CONFIRMATION:"
echo "  Pool:            $POOL"
echo "  Target Old Dev:  $OLD_DEV"
echo "  New Drive ID:    $NEW_DEV"
echo "  New Drive Info:  $SELECTED_INFO"
echo "--------------------------------------------------------------------------------"

if echo "$SELECTED_INFO" | grep -q "\[IN POOL:"; then
    echo "WARNING: The selected drive appears to be actively in use by a ZFS pool!"
fi

read -rp "Are you sure you want to proceed with replacement? (y/N): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Operation canceled."
    exit 0
fi

echo
echo "Executing: zpool replace -f \"$POOL\" \"$OLD_DEV\" \"$NEW_DEV\""
if zpool replace -f "$POOL" "$OLD_DEV" "$NEW_DEV"; then
    echo
    echo "Success! Replacement initiated."
    echo "Monitoring pool status (Press Ctrl+C to exit status view):"
    echo "--------------------------------------------------------------------------------"
    sleep 2
    zpool status "$POOL"
else
    echo "Error: zpool replace failed." >&2
    exit 1
fi