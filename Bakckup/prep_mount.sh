#!/bin/bash
set -eu

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $*"; }

SMB_SHARE="$1"
SMB_USER="$2"
SMB_PASS="$3"
MOUNT_POINT="$4"          # e.g., /mnt/smbshare
BACKUP_DESTINATION="$5"   # e.g., /mnt/smbshare/dev-env

# --- 1. Preparation and Local Mount Point Creation ---

# Install cifs-utils (Logic omitted for brevity, assume it remains here)

# Create ONLY the local mount point directory
log "Creating local mount point directory: $MOUNT_POINT"
mkdir -p "$MOUNT_POINT"

# DO NOT create $BACKUP_DESTINATION yet!

# Check if the mount point is already mounted
if mountpoint -q "$MOUNT_POINT"; then
    log "Mount point $MOUNT_POINT is already mounted. Attempting to unmount first..."
    sudo umount -l "$MOUNT_POINT" 2>/dev/null || true
fi

# --- 2. Mount the SMB share ---
log "Mounting SMB share $SMB_SHARE..."
sudo mount -t cifs "$SMB_SHARE" "$MOUNT_POINT" \
    -o username="$SMB_USER",password="$SMB_PASS",vers=3.0,dir_mode=0777,file_mode=0777,nobrl

MOUNT_STATUS=$?
if [ $MOUNT_STATUS -ne 0 ]; then
    log "Error: Failed to mount SMB share. Exit code: $MOUNT_STATUS"
    exit $MOUNT_STATUS
fi

# --- 3. CRITICAL FIX: Create the host directory ON THE MOUNTED SHARE ---
# Now that the SMB share is mounted over $MOUNT_POINT, the BACKUP_DESTINATION 
# is created on the remote share's file system.

log "Creating host destination directory ON THE MOUNTED SHARE: $BACKUP_DESTINATION"
mkdir -p "$BACKUP_DESTINATION"

if [ $? -ne 0 ]; then
    log "Fatal: Could not create host directory $BACKUP_DESTINATION on the mounted share."
    # Unmount if directory creation fails
    sudo umount -l "$MOUNT_POINT" 2>/dev/null || true
    exit 4
fi

log "Preparation successful."
exit 0