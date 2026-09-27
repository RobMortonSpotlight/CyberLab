#!/bin/bash
set -e

echo "[WINDOWS-WS] CyberLab Windows Workstation Simulation starting..."
echo "[WINDOWS-WS] Simulating: Employee workstation in CYBERLAB domain"

# ============================================================================
# SMB CONFIGURATION
# ============================================================================
echo "[WINDOWS-WS] Configuring SMB shares..."
/usr/local/bin/smb-config.sh

# Create share directories and content
/usr/local/bin/create-shares.sh

# ============================================================================
# SAMBA SERVICES
# ============================================================================
echo "[WINDOWS-WS] Starting Samba services..."

# Ensure Samba directories exist
mkdir -p /var/run/samba
mkdir -p /var/lib/samba/private
mkdir -p /var/lib/samba/printers

# Start Samba daemon
service smbd start 2>/dev/null || smbd -D
service nmbd start 2>/dev/null || nmbd -D
sleep 2

echo "[WINDOWS-WS] Samba services started"
echo "[WINDOWS-WS]   - SMB file sharing (445)"
echo "[WINDOWS-WS]   - NetBIOS naming (137, 138)"
echo "[WINDOWS-WS]   - RPC services (135)"

# ============================================================================
# CREATE LAB USERS (Finding 08: Credential Reuse)
# ============================================================================
echo "[WINDOWS-WS] Creating workstation user accounts..."

# Create local user accounts (simulating Windows users)
useradd -m -s /bin/bash employee 2>/dev/null || true
echo "employee:EmployeePass123!" | chpasswd

# Reuse credentials from other systems (Finding 08)
useradd -m -s /bin/bash dataadmin 2>/dev/null || true
echo "dataadmin:cyberlab_db_pass_789" | chpasswd

# Admin user
useradd -m -s /bin/bash admin 2>/dev/null || true
echo "admin:AdminPass123!" | chpasswd

# Add Samba users
smbpasswd -a -n nobody 2>/dev/null || true
smbpasswd -a employee cyberlab_db_pass_789 2>/dev/null || true
smbpasswd -a dataadmin cyberlab_db_pass_789 2>/dev/null || true
smbpasswd -a admin AdminPass123! 2>/dev/null || true

echo "[WINDOWS-WS] User accounts configured"

# ============================================================================
# SHARE CONTENT (Finding 10: Information Leakage)
# ============================================================================
echo "[WINDOWS-WS] Populating shares with intentional findings..."

# Public share - contains clues
cat > /var/samba-shares/public/README.txt << 'EOF'
CyberLab Network - Employee Workstation
========================================

This workstation is part of the CYBERLAB network.

Important Contacts:
- System Admin: admin@cyberlab.local
- Help Desk: support@cyberlab.local
- Infrastructure: infrastructure@cyberlab.local

Network Resources:
- File Server: \\server.cyberlab.local\data
- Backup Service: backup.cyberlab.local:9000
- Admin Console: https://admin.cyberlab.local:8443

For access to internal resources, contact the Help Desk.
EOF

# Data share - contains sensitive information (Finding 10)
cat > /var/samba-shares/data/NETWORK_MAP.txt << 'EOF'
CyberLab Network Topology
==========================

External Network: 10.0.1.0/24
  - Firewall Gateway: 10.0.1.1
  - Student Access Point: 10.0.1.100

Internal Network: 192.168.1.0/24 (Behind Firewall)
  - Firewall/Router: 192.168.1.1
  - Linux App Server: 192.168.1.10 (Entry point after compromise)
  - Employee Workstation (this): 192.168.1.20
  - File Server: 192.168.1.30
  - BMC/Management: 192.168.1.50

CRITICAL: Windows Server (192.168.1.30) requires administrative credentials
Email internal documentation to: infrastructure@cyberlab.local
EOF

cat > /var/samba-shares/data/CREDENTIALS_BACKUP.txt << 'EOF'
BACKUP CREDENTIALS FILE
(This should be deleted before production - TEST ONLY)

System Accounts (Credential Reuse - Finding 08):
- User: dataadmin
- Password: cyberlab_db_pass_789
- Used on: Linux Server, Windows Server, Database

Administrative Account:
- User: admin
- Password: AdminPass123!
- Used on: Linux Server, Windows Workstation

Windows Server Access:
- User: Administrator
- Password: AdminPass123!

Database Access:
- Server: 192.168.1.30:5432
- Database: cyberlab_prod
- User: dataadmin
- Password: cyberlab_db_pass_789

NOTE: Credential reuse is a significant risk!
Each system should have unique credentials.
EOF

# Admin share - restricted (Finding 14)
cat > /var/samba-shares/admin/DEPLOYMENT_NOTES.txt << 'EOF'
Internal Deployment Notes

File Server Configuration:
- Location: 192.168.1.30
- Shares: \data, \backup, \admin
- Authentication: NTLM

Backup Service:
- Server: backup.cyberlab.local:9000
- Status: Running
- Last backup: 2024-01-15 02:00 UTC

Security Notes:
- Firewall blocks ICMP to Windows Server and BMC
- Use nmap -Pn for discovery when ping fails
- SMB signing is disabled (intentional lab configuration)

FINDING 11 - NTLM Exposure:
NTLM authentication can be captured using tcpdump
or Wireshark on the network segment.

Vulnerable systems:
- Windows Workstation (this system)
- Windows Server
EOF

chmod 644 /var/samba-shares/data/*.txt
chmod 640 /var/samba-shares/admin/*.txt
chmod 644 /var/samba-shares/public/*.txt

# ============================================================================
# SIMULATE WINDOWS SERVICES
# ============================================================================
echo "[WINDOWS-WS] Simulating additional Windows services..."

# Create RPC endpoint mapping simulation
echo "RPC Endpoint Mapping Service: Active" > /tmp/rpc-status

# Create NTLM authentication log for analysis
touch /var/log/cyberlab/ntlm-auth.log
chmod 644 /var/log/cyberlab/ntlm-auth.log

# ============================================================================
# PACKET CAPTURE
# ============================================================================
echo "[WINDOWS-WS] Starting packet capture for NTLM analysis..."
tcpdump -i any -w /var/log/cyberlab/workstation-traffic.pcap \
    'port 139 or port 445 or port 135 or udp port 137 or udp port 138' \
    2>/dev/null &
TCPDUMP_PID=$!
echo $TCPDUMP_PID > /var/run/tcpdump.pid

# ============================================================================
# HEALTH CHECK
# ============================================================================
echo "[WINDOWS-WS] Verifying SMB services..."
smbclient -L localhost -N 2>/dev/null | grep -q public && echo "[WINDOWS-WS] SMB Services: OK" || true

# Signal health
touch /tmp/smb-healthy

echo "[WINDOWS-WS] =========================================="
echo "[WINDOWS-WS] Windows Workstation ready for access"
echo "[WINDOWS-WS] Services running:"
echo "[WINDOWS-WS]   - SMB File Sharing (445)"
echo "[WINDOWS-WS]   - NetBIOS Naming (137, 138)"
echo "[WINDOWS-WS]   - RPC Services (135)"
echo "[WINDOWS-WS] Shares available:"
echo "[WINDOWS-WS]   - \\ws-employee\public"
echo "[WINDOWS-WS]   - \\ws-employee\data"
echo "[WINDOWS-WS]   - \\ws-employee\admin (restricted)"
echo "[WINDOWS-WS] =========================================="

# Keep container running
tail -f /dev/null &
wait $!
