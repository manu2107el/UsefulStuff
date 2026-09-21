#!/usr/bin/env bash

set -euo pipefail

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root." >&2
   exit 1
fi

# Check for required tools
if ! command -v zpool &> /dev/null; then
    echo "Error: zpool command not found. Is ZFS installed?" >&2
    exit 1
fi

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
echo "Enter the Device Name, GUID, or ID of the drive to replace from above"
echo "Examples: 1234567890123456789, sdc, or vdev name (e.g. UNAVAIL):"
read -rp "Old Device / GUID: " OLD_DEV

if [[ -z "$OLD_DEV" ]]; then
    echo "Error: Old device cannot be empty." >&2
    exit 1
fi

# 3. Select New Replacement Drive by ID
echo
echo "Available drives in /dev/disk/by-id/:"
echo "------------------------------------------"

# Map available disk IDs (filtering out partitions)
mapfile -t disk_ids < <(ls -l /dev/disk/by-id/ | grep -v 'part' | awk '{print $9}' | grep -E '^(ata|nvme|scsi|wwn)-' | sort -u)

if [[ ${#disk_ids[@]} -eq 0 ]]; then
    echo "Error: No disk IDs found in /dev/disk/by-id/." >&2
    exit 1
fi

select NEW_DEV_NAME in "${disk_ids[@]}"; do
    if [[ -n "${NEW_DEV_NAME:-}" ]]; then
        NEW_DEV="/dev/disk/by-id/$NEW_DEV_NAME"
        break
    else
        echo "Invalid selection. Please select a drive from the list."
    fi
done

echo
echo "------------------------------------------"
echo "CONFIRMATION:"
echo "  Pool:        $POOL"
echo "  Old Device:  $OLD_DEV"
echo "  New Drive:   $NEW_DEV"
echo "------------------------------------------"
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
    echo "------------------------------------------"
    sleep 2
    zpool status "$POOL"
else
    echo "Error: zpool replace failed." >&2
    exit 1
fi