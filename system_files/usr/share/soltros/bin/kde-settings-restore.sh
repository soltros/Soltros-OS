#!/bin/bash

# Stop the Plasma shell before restoring to prevent conflicts
killall plasmashell 2>/dev/null || true

# Check if the backup directory exists
BACKUP_DIR="/usr/share/soltros/settings/soltros-look/"
if [ ! -d "${BACKUP_DIR}" ]; then
    echo "Error: Backup directory not found at ${BACKUP_DIR}"
    exit 1
fi

echo "Restoring KDE Plasma settings from: ${BACKUP_DIR}"

# --- Copy Configuration Files ---
cp -a "${BACKUP_DIR}/configs/." "${HOME}/.config/"

# --- Copy Theme and Resource Files ---
cp -a "${BACKUP_DIR}/share/." "${HOME}/.local/share/"
cp -a "${BACKUP_DIR}/home_share/." "${HOME}/"

# Restart the Plasma shell to apply changes
kstart5 plasmashell
echo "Restore complete! You may need to log out and back in to see all changes."
