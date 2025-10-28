#!/bin/bash

source "$(dirname "$0")/config.sh"

# Function to apply retention policy
apply_retention_policy() {
    local snapshots=($(find "$BACKUP_DEST" -name "*.gpg" -type f | sort))
    local total_snapshots=${#snapshots[@]}
    
    echo "Current snapshots: $total_snapshots"
    echo "Retention policy: Daily=$KEEP_DAILY, Weekly=$KEEP_WEEKLY, Monthly=$KEEP_MONTHLY"
    
    if [ $total_snapshots -le $((KEEP_DAILY + KEEP_WEEKLY + KEEP_MONTHLY)) ]; then
        echo "No snapshots to remove (within retention limits)"
        return 0
    fi
    
    # Group snapshots by time period
    local daily=()
    local weekly=()
    local monthly=()
    
    for snapshot in "${snapshots[@]}"; do
        local snapshot_date=$(get_snapshot_date "$snapshot")
        local age_days=$(( ( $(date +%s) - $(date -d "$snapshot_date" +%s) ) / 86400 ))
        
        if [ $age_days -le 7 ]; then
            daily+=("$snapshot")
        elif [ $age_days -le 30 ]; then
            weekly+=("$snapshot")
        else
            monthly+=("$snapshot")
        fi
    done
    
    # Remove excess snapshots
    remove_excess_snapshots "daily" daily $KEEP_DAILY
    remove_excess_snapshots "weekly" weekly $KEEP_WEEKLY
    remove_excess_snapshots "monthly" monthly $KEEP_MONTHLY
}

# Helper function to get snapshot date from filename
get_snapshot_date() {
    local snapshot_file="$1"
    local filename=$(basename "$snapshot_file")
    # Extract date from snapshot_YYYYMMDD_HHMMSS pattern
    local date_part=$(echo "$filename" | grep -oE '[0-9]{8}_[0-9]{6}' | head -1)
    echo "${date_part:0:4}-${date_part:4:2}-${date_part:6:2} ${date_part:9:2}:${date_part:11:2}:${date_part:13:2}"
}

# Function to remove excess snapshots
remove_excess_snapshots() {
    local type="$1"
    local -n snapshots_array=$2
    local keep_count=$3
    
    local excess_count=$(( ${#snapshots_array[@]} - keep_count ))
    
    if [ $excess_count -gt 0 ]; then
        echo "Removing $excess_count excess $type snapshots..."
        for ((i=0; i<excess_count; i++)); do
            echo "Removing: $(basename "${snapshots_array[$i]}")"
            rm -f "${snapshots_array[$i]}"
        done
    fi
}

# Function to show disk usage
show_disk_usage() {
    echo "Backup Disk Usage:"
    du -sh "$BACKUP_DEST"
    echo -e "\nSnapshot count:"
    find "$BACKUP_DEST" -name "*.gpg" -type f | wc -l
}

main() {
    case "${1:-}" in
        "apply")
            apply_retention_policy
            ;;
        "status")
            show_disk_usage
            ;;
        "cleanup")
            echo "This will remove snapshots according to retention policy."
            read -p "Are you sure? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                apply_retention_policy
            fi
            ;;
        *)
            echo "Usage: $0 {apply|status|cleanup}"
            echo "  apply   - Apply retention policy"
            echo "  status  - Show disk usage and snapshot count"
            echo "  cleanup - Interactive cleanup with confirmation"
            exit 1
            ;;
    esac
}

main "$@"
