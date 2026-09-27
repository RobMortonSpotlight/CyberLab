#!/bin/bash

echo "[USERS] Creating lab user accounts..."

# Create FTP user
useradd -m -d /var/ftp -s /usr/sbin/nologin ftp 2>/dev/null || true
chmod 755 /var/ftp

# Create standard lab users with intentional weak credentials (Finding 15: Default Credentials)
# These credentials will be reused elsewhere (Finding 08: Credential Reuse)

# Admin user with weak password
useradd -m -s /bin/bash -G sudo admin 2>/dev/null || true
echo "admin:AdminPass123!" | chpasswd

# Standard user with weak password (credential reuse scenario)
useradd -m -s /bin/bash student 2>/dev/null || true
echo "student:StudentPass123" | chpasswd

# Database admin (password will be reused on Windows Server)
useradd -m -s /bin/bash dataadmin 2>/dev/null || true
echo "dataadmin:cyberlab_db_pass_789" | chpasswd

# Service account with elevated privileges (Finding 13: Excessive Privileges)
useradd -m -s /bin/bash -G sudo service-admin 2>/dev/null || true
echo "service-admin:ServicePass456!" | chpasswd

# FTP-only user (for ProFTPD testing)
useradd -m -d /var/ftp/pub -s /usr/sbin/nologin ftpuser 2>/dev/null || true
echo "ftpuser:FTPPass789" | chpasswd

# Create anonymous FTP capability
useradd -m -d /var/ftp -s /usr/sbin/nologin -u 100 ftp-anon 2>/dev/null || true

# Create test user (mentioned in HTML comments)
useradd -m -s /bin/bash testuser 2>/dev/null || true
echo "testuser:testpass123" | chpasswd

echo "[USERS] Lab user accounts created successfully"
echo "[USERS] Note: These are intentionally weak credentials for learning purposes"
