#!/bin/bash
set -eu

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $*"; }

SMB_SHARE="$1"
SMB_USER="$2"
SMB_PASS="$3"
MOUNT_POINT="$4"
BACKUP_DESTINATION="$5"

# Install cifs-utils
if command -v apt >/dev/null 2>&1; then
    log "Installing cifs-utils via apt..."
    sudo DEBIAN_FRONTEND=noninteractive apt install -y cifs-utils > /dev/null
elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
    log "Installing cifs-utils via yum/dnf..."
    sudo yum install -y cifs-utils > /dev/null || sudo dnf install -y cifs-utils > /dev/null
else
    log "Warning: Could not detect package manager for cifs-utils installation."
fi

# Create mount point and host directory
log "Creating mount point: $MOUNT_POINT"
mkdir -p "$MOUNT_POINT"
log "Creating mount point: $BACKUP_DESTINATION"
mkdir -p "$BACKUP_DESTINATION"

# Check if the mount point is already mounted
if mountpoint -q "$MOUNT_POINT"; then
    log "Mount point $MOUNT_POINT is already mounted. Attempting to unmount first..."
    sudo umount -l "$MOUNT_POINT" 2>/dev/null || true # Soft unmount, ignore errors
fi

# Mount the SMB share using credentials
log "Mounting SMB share $SMB_SHARE..."
sudo mount -t cifs "$SMB_SHARE" "$MOUNT_POINT" \
    -o username="$SMB_USER",password="$SMB_PASS",vers=3.0,dir_mode=0777,file_mode=0777,nobrl
exit $?