#!/bin/bash

# Arguments: <source_directory> <destination_directory>
SOURCE_DIR="$1"
DEST_DIR="$2"

# Function to handle logging (outputs to STDOUT for Komodo to capture)
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# --- Validation ---

if [ "$#" -ne 2 ]; then
    log "Error: Script requires two arguments: <source_directory> <destination_directory>."
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    log "Error: Source directory '$SOURCE_DIR' does not exist."
    exit 2
fi

# DEST_DIR must be created/mounted by the Komodo Action before this script runs
if [ ! -d "$DEST_DIR" ]; then
    log "Error: Destination directory '$DEST_DIR' does not exist or is not accessible."
    exit 3
fi

# --- Main Backup Logic ---

log "Starting structured backup from $SOURCE_DIR to $DEST_DIR"
GLOBAL_EXIT_CODE=0

# Iterate over each 'stack' directory (e.g., stack1, stack2)
find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -type d | while IFS= read -r stack_path; do
    
    stack_name=$(basename "$stack_path")
    stack_dest_dir="$DEST_DIR/$stack_name"

    mkdir -p "$stack_dest_dir" || { log "Fatal: Could not create stack destination dir $stack_dest_dir"; GLOBAL_EXIT_CODE=4; break; }
    log "Processing Stack: $stack_name"

    # Iterate over items inside the current stack directory
    find "$stack_path" -mindepth 1 -maxdepth 1 | while IFS= read -r item_path; do
        
        item_name=$(basename "$item_path")
        
        if [ -d "$item_path" ]; then
            # Directory (Volume): TAR and GZIP it
            output_file="$stack_dest_dir/${item_name}.tar.gz"
            
            tar -czf "$output_file" -C "$(dirname "$item_path")" "$item_name" 2>/dev/null
            
            if [ $? -eq 0 ]; then
                log "  SUCCESS: Volume '$item_name' backed up."
            else
                log "  FAILURE: Volume '$item_name' tar operation failed."
                GLOBAL_EXIT_CODE=5 # Set failure code but continue
            fi

        elif [ -f "$item_path" ]; then
            # File: Simply copy it
            output_file="$stack_dest_dir/$item_name"
            
            cp "$item_path" "$output_file"
            
            if [ $? -eq 0 ]; then
                log "  SUCCESS: File '$item_name' copied."
            else
                log "  FAILURE: File '$item_name' copy operation failed."
                GLOBAL_EXIT_CODE=5 # Set failure code but continue
            fi

        fi
    
    done
done

log "Backup script finished. Exiting with code: $GLOBAL_EXIT_CODE"
exit $GLOBAL_EXIT_CODE