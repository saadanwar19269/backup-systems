#!/bin/bash

echo "Backup System Setup"
echo "==================="

# Make scripts executable
chmod +x backup.sh restore.sh list-snapshots.sh verify-backup.sh retention-manager.sh

# Create default configuration if it doesn't exist
if [ ! -f config.sh ]; then
    echo "Creating default configuration..."
    cat > config.sh << 'EOF'
#!/bin/bash

# Backup System Configuration
CONFIG_VERSION="1.0"

# Source directory to backup
BACKUP_SOURCE="$HOME/important-data"

# Backup destination directory
BACKUP_DEST="$HOME/backups"

# GPG recipient (your email or key ID)
GPG_RECIPIENT=""

# GPG key for encryption (leave empty for symmetric encryption)
GPG_KEY=""

# Retention policy
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=12

# Rsync options
RSYNC_OPTS="-avh --delete --progress"

# Snapshot naming
SNAPSHOT_PREFIX="snapshot"
DATE_FORMAT="+%Y%m%d_%H%M%S"

# Logging
LOG_DIR="$HOME/.backup-logs"
VERBOSE=true
EOF
    echo "Please edit config.sh with your settings before running backups."
fi

# Test for dependencies
echo "Checking dependencies..."
for cmd in rsync gpg tar; do
    if command -v "$cmd" &> /dev/null; then
        echo "✓ $cmd"
    else
        echo "✗ $cmd (missing)"
    fi
done

echo -e "\nSetup complete!"
echo "Next steps:"
echo "1. Edit config.sh with your settings"
echo "2. Run: ./backup.sh init"
echo "3. Run: ./backup.sh run"
