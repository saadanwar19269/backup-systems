# Linux Backup & Incremental Snapshot System

A robust, encrypted backup system using rsync and GPG with incremental snapshots, retention policies, and easy restoration.

## Features

- 🔒 **Encrypted Backups**: GPG encryption (symmetric or asymmetric)
- 📊 **Incremental Snapshots**: Hardlink-based deduplication
- 🗂️ **Retention Policies**: Keep daily, weekly, monthly snapshots
- 🔍 **Metadata Tracking**: JSON metadata for each snapshot
- 🛠️ **Easy Restoration**: Interactive and direct restore options
- 📝 **Comprehensive Logging**: Detailed operation logs
- 🧪 **Verification**: Backup integrity checking

## Quick Start

**1. Setup :**

chmod +x setup.sh

./setup.sh

**2. Configure:**

Edit config.sh with your settings:

BACKUP_SOURCE: Directory to backup
BACKUP_DEST: Backup destination
GPG_RECIPIENT: Your GPG key (optional)

**3. Initialize:**
./backup.sh init

**4. First Backup:**

./backup.sh run

# Usage

**Regular Backups**

./backup.sh run

**List Snapshots**

./restore.sh list

**Restore Files**

## Interactive restore

./restore.sh interactive

## Direct restore

./restore.sh restore snapshot_file.gpg /restore/path

## Manage Retention

## Show status

./retention-manager.sh status

## Apply retention policy

./retention-manager.sh apply

## Verify Backups

./backup.sh verify

## Configuration
Key settings in config.sh:

Retention: KEEP_DAILY, KEEP_WEEKLY, KEEP_MONTHLY
Encryption: Set GPG_RECIPIENT for asymmetric, leave empty for symmetric
Rsync Options: Modify RSYNC_OPTS for different behavior

Automation

Add to crontab for automatic backups:

**Daily backup at 2 AM**
0 2 * * * /path/to/backup-system/backup.sh run

**Weekly retention cleanup**
0 3 * * 0 /path/to/backup-system/retention-manager.sh apply
