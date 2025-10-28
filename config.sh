#!/bin/bash

# Backup System Configuration
CONFIG_VERSION="1.0"

# Source directory to backup
BACKUP_SOURCE="$HOME/important-data"

# Backup destination directory
BACKUP_DEST="$HOME/backups"

# GPG recipient (your email or key ID)
GPG_RECIPIENT="your-email@example.com"

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
