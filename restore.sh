#!/bin/bash

source "$(dirname "$0")/config.sh"

# Function to list available snapshots
list_snapshots() {
    find "$BACKUP_DEST" -name "*.gpg" -type f | sort
}

# Function to decrypt and extract snapshot
restore_snapshot() {
    local snapshot_file="$1"
    local restore_path="$2"
    local temp_dir=$(mktemp -d)
    
    if [ ! -f "$snapshot_file" ]; then
        echo "Snapshot not found: $snapshot_file"
        return 1
    fi
    
    if [ ! -d "$restore_path" ]; then
        echo "Restore path does not exist: $restore_path"
        return 1
    fi
    
    echo "Restoring from: $(basename "$snapshot_file")"
    echo "Restoring to: $restore_path"
    
    # Decrypt
    echo "Decrypting backup..."
    local decrypted_file="$temp_dir/$(basename "$snapshot_file" .gpg)"
    if gpg --output "$decrypted_file" --decrypt "$snapshot_file"; then
        echo "Decryption successful"
    else
        echo "Decryption failed"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Extract
    echo "Extracting files..."
    if tar -xz -C "$restore_path" -f "$decrypted_file"; then
        echo "Extraction successful"
    else
        echo "Extraction failed"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    echo "Restore completed successfully"
}

# Function to preview snapshot contents
preview_snapshot() {
    local snapshot_file="$1"
    local temp_dir=$(mktemp -d)
    
    # Decrypt to temporary location
    local decrypted_file="$temp_dir/$(basename "$snapshot_file" .gpg)"
    gpg --output "$decrypted_file" --decrypt "$snapshot_file" 2>/dev/null
    
    # List contents
    echo "Snapshot contents:"
    tar -tzf "$decrypted_file" | head -20
    echo "..."
    
    # Show metadata if exists
    local metadata=$(tar -xz -O -f "$decrypted_file" "*/metadata.json" 2>/dev/null | head -10)
    if [ -n "$metadata" ]; then
        echo -e "\nMetadata:"
        echo "$metadata"
    fi
    
    rm -rf "$temp_dir"
}

# Interactive restore
interactive_restore() {
    echo "Available snapshots:"
    local snapshots=($(list_snapshots))
    
    if [ ${#snapshots[@]} -eq 0 ]; then
        echo "No snapshots found"
        return 1
    fi
    
    for i in "${!snapshots[@]}"; do
        echo "$((i+1)). $(basename "${snapshots[$i]}")"
    done
    
    echo -e "\nSelect snapshot to restore (1-${#snapshots[@]}): "
    read -r choice
    
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#snapshots[@]} ]; then
        echo "Invalid selection"
        return 1
    fi
    
    local selected_snapshot="${snapshots[$((choice-1))]}"
    
    echo -e "\nSelect action:"
    echo "1. Restore to directory"
    echo "2. Preview contents"
    echo "3. Show metadata"
    read -r action
    
    case $action in
        1)
            echo "Enter restore path: "
            read -r restore_path
            restore_snapshot "$selected_snapshot" "$restore_path"
            ;;
        2)
            preview_snapshot "$selected_snapshot"
            ;;
        3)
            show_metadata "$selected_snapshot"
            ;;
        *)
            echo "Invalid action"
            ;;
    esac
}

main() {
    case "${1:-}" in
        "list")
            list_snapshots
            ;;
        "restore")
            if [ $# -lt 3 ]; then
                echo "Usage: $0 restore <snapshot_file> <restore_path>"
                exit 1
            fi
            restore_snapshot "$2" "$3"
            ;;
        "preview")
            if [ $# -lt 2 ]; then
                echo "Usage: $0 preview <snapshot_file>"
                exit 1
            fi
            preview_snapshot "$2"
            ;;
        "interactive")
            interactive_restore
            ;;
        *)
            echo "Usage: $0 {list|restore|preview|interactive}"
            echo "  list         - List available snapshots"
            echo "  restore      - Restore snapshot to path"
            echo "  preview      - Preview snapshot contents"
            echo "  interactive  - Interactive restore menu"
            exit 1
            ;;
    esac
}

main "$@"
