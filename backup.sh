#!/bin/bash

# Load configuration
source "$(dirname "$0")/config.sh"

# Initialize
source "$(dirname "$0")/init.sh"

# Function to create snapshot
create_snapshot() {
    local snapshot_name="${SNAPSHOT_PREFIX}_$(date "$DATE_FORMAT")"
    local snapshot_path="$BACKUP_DEST/$snapshot_name"
    local metadata_file="$snapshot_path/metadata.json"
    
    log "Starting backup: $snapshot_name"
    
    # Create snapshot directory
    mkdir -p "$snapshot_path"
    
    # Create hardlink reference if previous snapshot exists
    local previous_snapshot=$(find_previous_snapshot)
    local link_dest=""
    if [ -n "$previous_snapshot" ]; then
        link_dest="--link-dest=$previous_snapshot"
        log "Using previous snapshot for hardlinks: $(basename "$previous_snapshot")"
    fi
    
    # Perform rsync backup
    log "Starting rsync..."
    if rsync $RSYNC_OPTS $link_dest "$BACKUP_SOURCE/" "$snapshot_path/data/"; then
        log "Rsync completed successfully"
    else
        log "Rsync completed with warnings" "WARNING"
    fi
    
    # Create metadata
    create_metadata "$snapshot_name" "$previous_snapshot" "$metadata_file"
    
    # Create archive and encrypt
    if create_encrypted_archive "$snapshot_path" "$snapshot_name"; then
        log "Encrypted archive created successfully"
        # Remove unencrypted data
        rm -rf "$snapshot_path/data"
    else
        log "Failed to create encrypted archive" "ERROR"
        return 1
    fi
    
    log "Backup completed: $snapshot_name"
    return 0
}

# Function to find previous snapshot
find_previous_snapshot() {
    find "$BACKUP_DEST" -maxdepth 1 -name "${SNAPSHOT_PREFIX}_*" -type d | \
    grep -v "\.gpg$" | \
    sort | \
    tail -n 1
}

# Function to create metadata
create_metadata() {
    local snapshot_name="$1"
    local previous_snapshot="$2"
    local metadata_file="$3"
    
    local previous_name=""
    if [ -n "$previous_snapshot" ]; then
        previous_name=$(basename "$previous_snapshot")
    fi
    
    cat > "$metadata_file" << EOF
{
    "name": "$snapshot_name",
    "timestamp": "$(date -Iseconds)",
    "type": "$(if [ -z "$previous_snapshot" ]; then echo "full"; else echo "incremental"; fi)",
    "parent": "$previous_name",
    "size_bytes": $(du -sb "$snapshot_path/data" | cut -f1),
    "file_count": $(find "$snapshot_path/data" -type f | wc -l),
    "source_directory": "$BACKUP_SOURCE",
    "backup_system_version": "$CONFIG_VERSION"
}
EOF
    
    log "Metadata created: $metadata_file"
}

# Function to create encrypted archive
create_encrypted_archive() {
    local snapshot_path="$1"
    local snapshot_name="$2"
    local archive_name="$snapshot_path.tar.gz"
    
    log "Creating encrypted archive..."
    
    # Create tar archive
    if tar -cz -C "$BACKUP_DEST" -f "$archive_name" "$snapshot_name"; then
        log "Tar archive created: $archive_name"
    else
        log "Failed to create tar archive" "ERROR"
        return 1
    fi
    
    # Encrypt with GPG
    if [ -n "$GPG_KEY" ]; then
        # Asymmetric encryption
        gpg --encrypt --recipient "$GPG_RECIPIENT" --output "$archive_name.gpg" "$archive_name"
    else
        # Symmetric encryption (will prompt for password)
        gpg --symmetric --output "$archive_name.gpg" "$archive_name"
    fi
    
    if [ $? -eq 0 ]; then
        log "Encryption completed: $archive_name.gpg"
        # Remove unencrypted tar
        rm -f "$archive_name"
        return 0
    else
        log "Encryption failed" "ERROR"
        return 1
    fi
}

# Main execution
main() {
    case "${1:-}" in
        "init")
            initialize_backup_system
            ;;
        "run")
            create_snapshot
            ;;
        "verify")
            verify_backup
            ;;
        *)
            echo "Usage: $0 {init|run|verify}"
            echo "  init  - Initialize backup system"
            echo "  run   - Create new snapshot"
            echo "  verify - Verify latest backup"
            exit 1
            ;;
    esac
}

main "$@"
