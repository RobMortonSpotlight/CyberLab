#!/bin/bash

echo "[SHARES] Creating file server shares..."

# Create share directories
mkdir -p /var/samba-shares/data
mkdir -p /var/samba-shares/backup/full
mkdir -p /var/samba-shares/backup/incremental
mkdir -p /var/samba-shares/admin
mkdir -p /var/samba-shares/public

# Set permissions
chmod 777 /var/samba-shares/data
chmod 777 /var/samba-shares/backup
chmod 777 /var/samba-shares/backup/full
chmod 777 /var/samba-shares/backup/incremental
chmod 750 /var/samba-shares/admin
chmod 755 /var/samba-shares/public

echo "[SHARES] File server shares configured"
