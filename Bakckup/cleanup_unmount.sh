#!/bin/bash
# Must be executed after backup, even if backup fails.

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') - $*"; }

MOUNT_POINT="$1"

log "Starting cleanup..."

if mountpoint -q "$MOUNT_POINT"; then
    log "Unmounting SMB share $MOUNT_POINT..."
    # Use || true to ignore errors during unmount, preventing script failure on cleanup
    sudo umount -l "$MOUNT_POINT" 2>/dev/null || true
    log "Unmount complete."
else
    log "Mount point $MOUNT_POINT is not currently mounted. Skipping unmount."
fi

# Cleanup is complete, return success
exit 0