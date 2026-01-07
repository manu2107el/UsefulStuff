#!/bin/bash

# Arguments: <source_directory> <destination_base_directory>
SOURCE_DIR="$1"
DEST_BASE_DIR="$2" # This is now the base folder (e.g., /mnt/smbshare/dev-env)
MAX_BACKUPS=5      # Maximum number of dated backups to retain

# --- Function to handle logging (outputs to STDOUT for Komodo to capture) ---
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# --- Validation (R1, R2, R3) ---

if [ "$#" -ne 2 ]; then
    log "Error: Script requires two arguments: <source_directory> <destination_base_directory>."
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    log "Error: Source directory '$SOURCE_DIR' does not exist."
    exit 2
fi

# Ensure the base directory exists before attempting retention/backup
if [ ! -d "$DEST_BASE_DIR" ]; then
    log "Error: Destination base directory '$DEST_BASE_DIR' does not exist or is not accessible."
    exit 3
fi

# --- 1. Retention Policy: Manage Backup Count ---

log "Checking retention policy (Max: $MAX_BACKUPS backups) in $DEST_BASE_DIR..."

# Find all dated backup folders (using a standard YYYYMMDD format)
# The '-type d' ensures we only look at directories.
BACKUP_FOLDERS=$(find "$DEST_BASE_DIR" -mindepth 1 -maxdepth 1 -type d -regextype posix-egrep -regex ".*[0-9]{14}" | sort)
BACKUP_COUNT=$(echo "$BACKUP_FOLDERS" | wc -l)
GLOBAL_EXIT_CODE=0

if [ "$BACKUP_COUNT" -ge "$MAX_BACKUPS" ]; then
    # Identify the oldest folder (which is the first line after sorting)
    OLDEST_FOLDER=$(echo "$BACKUP_FOLDERS" | head -n 1 | xargs)
    
    if [ -n "$OLDEST_FOLDER" ]; then
        log "Retention limit reached ($BACKUP_COUNT). Removing oldest backup: $OLDEST_FOLDER"
        
        # Use 'rm -rf' to remove the directory and its contents
        rm -rf "$OLDEST_FOLDER"
        
        if [ $? -eq 0 ]; then
            log "Successfully removed oldest backup."
        else
            log "WARNING: Failed to remove oldest backup: $OLDEST_FOLDER. Continuing backup process."
            # We don't exit here, as failure to clean up shouldn't prevent a new backup.
        fi
    fi
else
    log "Backup count ($BACKUP_COUNT) is below limit ($MAX_BACKUPS). No deletion required."
fi


# --- 2. Define New Date-Stamped Destination ---

# Format: YYYY-MM-DD_HH-MM (e.g., 2026-01-07_23:47:01)
DATE_STAMP=$(date '+%Y-%m-%d_%H:%M:%S')
DEST_DIR="$DEST_BASE_DIR/$DATE_STAMP"

log "Creating new dated destination folder: $DEST_DIR"
mkdir -p "$DEST_DIR" || { log "Fatal: Could not create date-stamped destination dir $DEST_DIR"; exit 4; }

# --- 3. Main Backup Logic (R4, R5, R6) ---

log "Starting structured backup from $SOURCE_DIR to $DEST_DIR"

# Iterate over each 'stack' directory (e.g., stack1, stack2)
# R4: Top-Level Iteration
find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d | while IFS= read -r stack_path; do
    
    stack_name=$(basename "$stack_path")
    # R5: Stack Destination Creation
    stack_dest_dir="$DEST_DIR/$stack_name"

    mkdir -p "$stack_dest_dir" || { log "Fatal: Could not create stack destination dir $stack_dest_dir"; GLOBAL_EXIT_CODE=4; break; }
    log "Processing Stack: $stack_name"

    # Iterate over items inside the current stack directory
    # R6: Item-Level Iteration
    find "$stack_path" -mindepth 1 -maxdepth 1 | while IFS= read -r item_path; do
        
        item_name=$(basename "$item_path")
        
        if [ -d "$item_path" ]; then
            # R7: Directory (Volume) Handling: TAR and GZIP it
            output_file="$stack_dest_dir/${item_name}.tar.gz"
            
            # Using -C "$(dirname "$item_path")" to ensure clean tar creation
            tar -czf "$output_file" -C "$(dirname "$item_path")" "$item_name" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                log "  SUCCESS: Volume '$item_name' backed up."
            else
                log "  FAILURE: Volume '$item_name' tar operation failed."
                GLOBAL_EXIT_CODE=5 # R10: Set failure code but continue
            fi

        elif [ -f "$item_path" ]; then
            # R8: File Handling: Simply copy it
            output_file="$stack_dest_dir/$item_name"
            
            cp "$item_path" "$output_file"
            
            if [ $? -eq 0 ]; then
                log "  SUCCESS: File '$item_name' copied."
            else
                log "  FAILURE: File '$item_name' copy operation failed."
                GLOBAL_EXIT_CODE=5 # R10: Set failure code but continue
            fi

        fi
    
    done
done

# R11: Final Exit Code
log "Backup script finished. Exiting with code: $GLOBAL_EXIT_CODE"
exit $GLOBAL_EXIT_CODE