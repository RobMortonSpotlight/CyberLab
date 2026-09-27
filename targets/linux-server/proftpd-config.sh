#!/bin/bash

echo "[PROFTPD] Configuring ProFTPD service..."

# Ensure ProFTPD directories exist
mkdir -p /var/run/proftpd
mkdir -p /var/log/cyberlab
mkdir -p /var/ftp/pub
mkdir -p /var/ftp/admin
mkdir -p /var/ftp/backup

# Set proper ownership
chown -R ftp:ftp /var/ftp 2>/dev/null || true
chmod 755 /var/ftp
chmod 755 /var/ftp/pub
chmod 750 /var/ftp/admin

# Ensure ProFTPD can write logs
touch /var/log/cyberlab/proftpd-transfer.log
touch /var/log/cyberlab/proftpd-access.log
touch /var/log/cyberlab/proftpd-auth.log
chmod 644 /var/log/cyberlab/proftpd*.log

echo "[PROFTPD] ProFTPD configuration complete"
