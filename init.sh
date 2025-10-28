#!/bin/bash

# Logging functions
log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_DIR/backup.log"
    
    if [ "$VERBOSE" = true ] && [ "$level" = "INFO" ]; then
        echo "$message"
    fi
}

# Initialize backup system
initialize_backup_system() {
    log "Initializing backup system..."
    
    # Create directories
    mkdir -p "$BACKUP_DEST" "$LOG_DIR"
    
    # Check if source exists
    if [ ! -d "$BACKUP_SOURCE" ]; then
        log "Source directory does not exist: $BACKUP_SOURCE" "ERROR"
        exit 1
    fi
    
    # Check for required tools
    for cmd in rsync gpg tar find du; do
        if ! command -v "$cmd" &> /dev/null; then
            log "Required command not found: $cmd" "ERROR"
            exit 1
        fi
    done
    
    # Test GPG
    if [ -n "$GPG_KEY" ]; then
        if ! gpg --list-keys "$GPG_RECIPIENT" &> /dev/null; then
            log "GPG key not found: $GPG_RECIPIENT" "ERROR"
            exit 1
        fi
    fi
    
    log "Backup system initialized successfully"
    log "Source: $BACKUP_SOURCE"
    log "Destination: $BACKUP_DEST"
}

# Verify backup system
verify_backup() {
    local latest_backup=$(find "$BACKUP_DEST" -name "*.gpg" -type f | sort | tail -n 1)
    
    if [ -z "$latest_backup" ]; then
        log "No backups found to verify" "WARNING"
        return 1
    fi
    
    log "Verifying backup: $(basename "$latest_backup")"
    
    # Test decryption (without extracting)
    if gpg --test "$latest_backup"; then
        log "Backup verification successful: $latest_backup"
        return 0
    else
        log "Backup verification failed: $latest_backup" "ERROR"
        return 1
    fi
}
