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
pools=()
while IFS= read -r p; do
    [[ -n "$p" ]] && pools+=("$p")
done < <(zpool list -H -o name)

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

# Fetch all top-level disk drives (type 'disk'), excluding loop/rom devices.
# Use lsblk -P (key="value" pairs) instead of plain columns: MODEL and
# MOUNTPOINT frequently contain spaces, which silently misaligns simple
# whitespace/awk column parsing.
disk_ids=()
display_labels=()

while IFS= read -r line; do
    dev_name="" dev_type="" dev_size="" dev_model="" dev_serial="" dev_fstype="" dev_mount=""
    rest="$line"
    while [[ "$rest" =~ ^([A-Z_]+)=\"([^\"]*)\"[[:space:]]*(.*)$ ]]; do
        key="${BASH_REMATCH[1]}"
        val="${BASH_REMATCH[2]}"
        rest="${BASH_REMATCH[3]}"
        case "$key" in
            NAME) dev_name="$val" ;;
            TYPE) dev_type="$val" ;;
            SIZE) dev_size="$val" ;;
            MODEL) dev_model="$val" ;;
            SERIAL) dev_serial="$val" ;;
            FSTYPE) dev_fstype="$val" ;;
            MOUNTPOINT) dev_mount="$val" ;;
        esac
    done

    [[ "$dev_type" == "disk" ]] || continue
    [[ -n "$dev_name" ]] || continue

    # Find persistent disk ID(s) for this device in /dev/disk/by-id/.
    # Prefer human-readable bus prefixes; fall back to whatever symlink
    # exists (covers virtio-, scsi-SATA_, google-, mmc-, usb-, wwn-, etc.)
    # instead of silently dropping the disk when the bus type is unusual.
    by_id_name=""
    while IFS= read -r candidate; do
        [[ -z "$candidate" ]] && continue
        if [[ "$candidate" =~ ^(ata|nvme|scsi|virtio)- ]]; then
            by_id_name="$candidate"
            break
        elif [[ -z "$by_id_name" ]]; then
            by_id_name="$candidate"
        fi
    done < <(ls -l /dev/disk/by-id/ 2>/dev/null | grep -vE -- '-part[0-9]+ ->' | grep -w -- "$dev_name$" | awk '{print $9}')

    if [[ -z "$by_id_name" ]]; then
        # No by-id entry found at all (rare) - fall back to the raw device
        # node rather than dropping the disk from the list.
        by_id_path="/dev/$dev_name"
        by_id_label="(no by-id entry) /dev/$dev_name"
    else
        by_id_path="/dev/disk/by-id/$by_id_name"
        by_id_label="$by_id_name"
    fi

    # Determine usage status
    status_tag="[AVAILABLE / UNUSED]"

    # Check if drive or partition is part of a ZFS pool
    if echo "$ALL_ZPOOL_STATUS" | grep -qw -- "$dev_name" || { [[ -n "$by_id_name" ]] && echo "$ALL_ZPOOL_STATUS" | grep -qF -- "$by_id_name"; }; then
        matched_pool=""
        for p in "${pools[@]}"; do
            if zpool status "$p" | grep -qE -- "$dev_name|$by_id_name"; then
                matched_pool="$p"
                break
            fi
        done
        status_tag="[IN POOL: ${matched_pool:-unknown}]"
    elif [[ -n "$dev_fstype" ]]; then
        status_tag="[USED: $dev_fstype]"
    elif [[ -n "$dev_mount" ]]; then
        status_tag="[MOUNTED: $dev_mount]"
    fi

    disk_ids+=("$by_id_path")
    display_labels+=("$by_id_label  |  Size: $dev_size  |  Model: ${dev_model:-unknown}  |  Serial: ${dev_serial:-unknown}  |  Status: $status_tag")
done < <(lsblk -d -P -o NAME,TYPE,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINT -e 7,11)

if [[ ${#disk_ids[@]} -eq 0 ]]; then
    echo "Error: No candidate drives found." >&2
    exit 1
fi

echo "Select Replacement Disk:"
PS3="Select drive number: "
select CHOICE in "${display_labels[@]}"; do
    if [[ -n "${CHOICE:-}" ]]; then
        index=$(( REPLY - 1 ))
        NEW_DEV="${disk_ids[$index]}"
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

if [[ "$SELECTED_INFO" == *"[IN POOL:"* ]]; then
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