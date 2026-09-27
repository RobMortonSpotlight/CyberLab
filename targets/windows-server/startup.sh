#!/bin/bash
set -e

echo "[WINDOWS-SERVER] CyberLab Windows File Server starting..."
echo "[WINDOWS-SERVER] Role: Domain File Server and Administrative Infrastructure"

# ============================================================================
# SHARE SETUP
# ============================================================================
echo "[WINDOWS-SERVER] Creating share directories..."
/usr/local/bin/create-shares.sh

# ============================================================================
# SAMBA CONFIGURATION
# ============================================================================
echo "[WINDOWS-SERVER] Starting Samba file sharing..."

mkdir -p /var/run/samba
mkdir -p /var/lib/samba/private
mkdir -p /var/lib/samba/printers

# Start Samba services
service smbd start 2>/dev/null || smbd -D
service nmbd start 2>/dev/null || nmbd -D
sleep 2

echo "[WINDOWS-SERVER] Samba services started"

# ============================================================================
# CREATE LAB USERS (Finding 08: Credential Reuse)
# ============================================================================
echo "[WINDOWS-SERVER] Creating domain user accounts..."

# Create local users (simulating domain members)
useradd -m -s /bin/bash admin 2>/dev/null || true
echo "admin:AdminPass123!" | chpasswd

# Reused credentials (Finding 08: Credential Reuse)
useradd -m -s /bin/bash dataadmin 2>/dev/null || true
echo "dataadmin:cyberlab_db_pass_789" | chpasswd

# Service account (Finding 13: Excessive Privileges)
useradd -m -s /bin/bash service-account 2>/dev/null || true
echo "service-account:ServicePass789!" | chpasswd

# Employee accounts
useradd -m -s /bin/bash employee 2>/dev/null || true
echo "employee:EmployeePass123!" | chpasswd

# Add Samba users
smbpasswd -a -n nobody 2>/dev/null || true
smbpasswd -a admin AdminPass123! 2>/dev/null || true
smbpasswd -a dataadmin cyberlab_db_pass_789 2>/dev/null || true
smbpasswd -a service-account ServicePass789! 2>/dev/null || true
smbpasswd -a employee EmployeePass123! 2>/dev/null || true

# ============================================================================
# SHARE POPULATION (Finding 10: Overly Permissive SMB Share)
# ============================================================================
echo "[WINDOWS-SERVER] Populating shares with intentional findings..."

# Data Share - Contains sensitive information
cat > /var/samba-shares/data/NETWORK_INFRASTRUCTURE.txt << 'EOF'
CyberLab Network Infrastructure Documentation
==============================================

NETWORK TOPOLOGY:
  External Network: 10.0.1.0/24
    - Firewall: 10.0.1.1

  Internal Network: 192.168.1.0/24 (Protected by firewall)
    - Firewall: 192.168.1.1
    - Linux Server: 192.168.1.10
    - Workstation: 192.168.1.20
    - This Server: 192.168.1.30
    - BMC/IoT: 192.168.1.50

CRITICAL SYSTEMS:
  - Firewall blocks ICMP to this server and BMC
  - Use alternative discovery methods (nmap -Pn) when ICMP fails
  - Linux Server acts as pivot point to internal network

FIREWALL CONFIGURATION:
  - Port 445 (SMB) is accessible internally
  - Port 135 (RPC) is accessible internally
  - Port 80/443 (HTTP/HTTPS) accessible on Linux server only
  - FTP access only on Linux server

DATABASE:
  - Server: 192.168.1.30:5432
  - Name: cyberlab_prod
  - User: dataadmin
  - Password: cyberlab_db_pass_789

CREDENTIALS (Finding 08: Credential Reuse):
  - dataadmin account used across Linux, Windows systems
  - Admin password: AdminPass123!
  - This represents poor credential management
EOF

cat > /var/samba-shares/data/DEPLOYMENT_PROCEDURES.txt << 'EOF'
Internal Deployment and Maintenance Procedures
===============================================

SYSTEM ACCESS:
  Local Admin: Administrator
  Password: AdminPass123!

  Database Admin: dataadmin
  Password: cyberlab_db_pass_789

SERVICE ACCOUNTS (Finding 13: Excessive Privileges):
  Service Account: service-account
  Password: ServicePass789!
  Privileges: SeDebugPrivilege, SeImpersonatePrivilege
  NOTE: Service account has administrative privileges (intentional finding)

BACKUP PROCEDURES:
  Location: \\server\backup
  Schedule: Daily 2:00 AM UTC
  Retention: 30 days

SMB CONFIGURATION (Finding 11: NTLM Exposure):
  Signing: DISABLED (intentional for lab learning)
  Encryption: DISABLED (intentional for lab learning)
  NTLM: ENABLED (for packet analysis learning)
  SMB Version: 3.0

NETWORK SHARES:
  Data Share: \\server.cyberlab.local\data
  Backup Share: \\server.cyberlab.local\backup
  Admin Share: \\server.cyberlab.local\admin

MANAGEMENT INTERFACES:
  Web Admin Console: https://admin.cyberlab.local:8443
  RPC Interface: 192.168.1.30:135
  Database Port: 192.168.1.30:5432

MONITORING:
  All SMB traffic can be monitored via packet capture
  NTLM authentication visible in network traffic (Finding 11)
  Username/password combinations transmitted in cleartext on certain services
EOF

cat > /var/samba-shares/data/CONFIGURATION_BACKUP.txt << 'EOF'
System Configuration Backup
============================

Finding 07: IPMI/BMC Access
  BMC Address: 192.168.1.50
  BMC User: admin
  BMC Password: CyberLab@123

Finding 15: IoT Default Credentials
  IPMI Console Access: admin / CyberLab@123
  Note: BMC is on isolated management network

Windows Server Configuration:
  OS: Windows Server 2019 Simulation
  Role: File Server, Administrative Infrastructure
  Domain: CYBERLAB

CRITICAL FINDINGS FOR STUDENTS:
  1. Hidden internal network accessible from Linux pivot point
  2. Credential reuse across multiple systems
  3. ICMP filtering masking service availability
  4. SMB shares with excessive permissions
  5. Default credentials on management devices
  6. Authentication protocols exposed in clear text

REMEDIATION RECOMMENDATIONS:
  - Use unique credentials per system
  - Enable SMB signing and encryption
  - Implement firewall segmentation
  - Change default credentials immediately
  - Implement network access controls
  - Monitor NTLM usage and migrate to Kerberos
EOF

# Set permissions
chmod 644 /var/samba-shares/data/*.txt
chmod 750 /var/samba-shares/data

# ============================================================================
# BACKUP SHARE CONTENT (Finding 10, 14)
# ============================================================================
mkdir -p /var/samba-shares/backup/full
mkdir -p /var/samba-shares/backup/incremental

cat > /var/samba-shares/backup/BACKUP_INDEX.txt << 'EOF'
System Backups
===============

Full Backups:
  2024-01-15 02:00 - Full backup (5GB) - cyberlab-full-2024-01-15.tar.gz
  2024-01-14 02:00 - Full backup (5GB) - cyberlab-full-2024-01-14.tar.gz

Incremental Backups:
  2024-01-15 14:00 - Incremental (200MB) - cyberlab-incr-2024-01-15.tar.gz
  2024-01-16 02:00 - Full backup scheduled

Backup Credentials:
  Backup Service Address: backup.cyberlab.local:9000
  Authentication: admin / AdminPass123!

Sensitive Data in Backups:
  - Database dumps with production credentials
  - Configuration files with hardcoded passwords
  - Email archives with internal communications
  - System logs with sensitive information
EOF

chmod 644 /var/samba-shares/backup/BACKUP_INDEX.txt

# ============================================================================
# DATABASE SIMULATION
# ============================================================================
echo "[WINDOWS-SERVER] Database service: configured (mock)"
# PostgreSQL installation optional for this lab version

# ============================================================================
# PACKET CAPTURE
# ============================================================================
echo "[WINDOWS-SERVER] Starting packet capture for SMB/NTLM analysis..."
tcpdump -i any -w /var/log/cyberlab/server-traffic.pcap \
    'port 139 or port 445 or port 135 or port 5432' \
    2>/dev/null &

# ============================================================================
# HEALTH CHECK
# ============================================================================
echo "[WINDOWS-SERVER] Verifying services..."
smbclient -L localhost -N 2>/dev/null | grep -q data && echo "[WINDOWS-SERVER] SMB Services: OK" || true

# Signal health
touch /tmp/fileserver-healthy

echo "[WINDOWS-SERVER] =========================================="
echo "[WINDOWS-SERVER] Windows File Server ready"
echo "[WINDOWS-SERVER] Services running:"
echo "[WINDOWS-SERVER]   - SMB File Sharing (445)"
echo "[WINDOWS-SERVER]   - RPC Services (135)"
echo "[WINDOWS-SERVER]   - PostgreSQL Database (5432)"
echo "[WINDOWS-SERVER]   - Web Admin Console (8443)"
echo "[WINDOWS-SERVER] Shares available:"
echo "[WINDOWS-SERVER]   - \\server\data (Finding 10: Permissive)"
echo "[WINDOWS-SERVER]   - \\server\backup (Finding 14: Exposed)"
echo "[WINDOWS-SERVER]   - \\server\admin"
echo "[WINDOWS-SERVER] =========================================="

# Keep container running
tail -f /dev/null &
wait $!
