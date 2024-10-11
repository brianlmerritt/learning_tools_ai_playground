#!/bin/bash

# Set PHP memory limit
export PHP_MEMORY_LIMIT=4G

# Navigate to Moodle directory
cd /var/www/html

# Loop through all .mbz files in the mounted backups directory
for backup_file in /mnt/backups/*.mbz; do
    if [ -f "$backup_file" ]; then
        echo "Restoring course from $backup_file"
        php admin/cli/restore_backup.php --file="$backup_file" --categoryid=1 --showdebugging
    fi
done

echo "All course restorations completed."
