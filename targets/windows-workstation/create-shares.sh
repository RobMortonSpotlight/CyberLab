#!/bin/bash

echo "[SHARES] Creating Samba share directories..."

# Create share directories
mkdir -p /var/samba-shares/public
mkdir -p /var/samba-shares/data
mkdir -p /var/samba-shares/admin
mkdir -p /var/lib/samba/printers
mkdir -p /var/lib/samba/print$

# Set permissions
chmod 755 /var/samba-shares/public
chmod 755 /var/samba-shares/data
chmod 750 /var/samba-shares/admin

# Make directories owned by samba user
chown -R 33:33 /var/samba-shares/public 2>/dev/null || true
chown -R 33:33 /var/samba-shares/data 2>/dev/null || true

echo "[SHARES] Share directories configured"
