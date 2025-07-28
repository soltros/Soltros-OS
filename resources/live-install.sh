#!/usr/bin/env bash
set -euo pipefail

IMAGE="ghcr.io/soltros/soltros-os:latest"

echo "=== SoltrOS Secure Installer ==="

read -rp "Enter target disk (e.g., /dev/sda or /dev/nvme0n1): " TARGET
if [ ! -b "$TARGET" ]; then
    echo "❌ Error: $TARGET is not a valid block device."
    exit 1
fi

echo "⚠️  WARNING: This will erase all data on $TARGET"
read -rp "Are you sure you want to continue? (yes/[no]): " CONFIRM
[[ "$CONFIRM" != "yes" ]] && { echo "Aborted."; exit 1; }

# Prompt for username and secure password
read -rp "Enter desired username: " NEWUSER
read -rsp "Enter password for $NEWUSER: " NEWPASS
echo
read -rsp "Confirm password: " CONFIRM_PASS
echo
[[ "$NEWPASS" != "$CONFIRM_PASS" ]] && { echo "❌ Passwords do not match."; exit 1; }

# Generate password hash using SHA-512
PASSHASH=$(openssl passwd -6 "$NEWPASS")

# Create temporary systemd unit for user creation
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/install.d"

# Create install.d config
cat > "$TMPDIR/install.d/99-create-user.conf" <<EOF
[Install]
AddFile=/etc/systemd/system/99-create-user.service:/etc/systemd/system/99-create-user.service
EnableService=99-create-user.service
EOF

# Create secure systemd service
cat > "$TMPDIR/install.d/99-create-user.service" <<EOF
[Unit]
Description=Create user $NEWUSER securely on first boot
ConditionPathExists=!/home/$NEWUSER

[Service]
Type=oneshot
ExecStart=/usr/sbin/useradd -m -G wheel -s /bin/bash -p '$PASSHASH' $NEWUSER
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Run bootc install with injected files
echo "🚀 Installing SoltrOS to $TARGET"
sudo bootc install \
    --image "$IMAGE" \
    --target "$TARGET" \
    --add-file "$TMPDIR/install.d/99-create-user.conf":/etc/bootc/install.d/99-create-user.conf \
    --add-file "$TMPDIR/install.d/99-create-user.service":/etc/systemd/system/99-create-user.service

# Clean up temp files
rm -rf "$TMPDIR"

echo "✅ Install complete! User '$NEWUSER' will be created securely on first boot."
