#!/bin/bash
set -e

echo "[LINUX-SERVER] CyberLab Linux Application Server starting..."
echo "[LINUX-SERVER] Hostname: $(hostname)"

# ============================================================================
# SSH CONFIGURATION
# ============================================================================
echo "[LINUX-SERVER] Configuring SSH service..."
/usr/local/bin/ssh-config.sh

# Start SSH daemon
service ssh start
echo "[LINUX-SERVER] SSH service started on port 22"

# ============================================================================
# WEB SERVER CONFIGURATION
# ============================================================================
echo "[LINUX-SERVER] Configuring Apache web server..."
/usr/local/bin/apache-config.sh

# Enable Apache modules
a2enmod ssl 2>/dev/null || true
a2enmod rewrite 2>/dev/null || true
a2enmod proxy 2>/dev/null || true
a2enmod headers 2>/dev/null || true

# Start Apache
service apache2 start
echo "[LINUX-SERVER] Apache web server started on ports 80/443"

# ============================================================================
# ProFTPD CONFIGURATION (Intentionally Vulnerable)
# ============================================================================
echo "[LINUX-SERVER] Configuring ProFTPD service (Learning Target)..."
/usr/local/bin/proftpd-config.sh

# Create FTP home directories
mkdir -p /var/ftp/pub
mkdir -p /var/ftp/admin
chmod 755 /var/ftp/pub
chmod 750 /var/ftp/admin

# Create intentional data leak files for FTP
cat > /var/ftp/pub/README.txt << 'EOF'
CyberLab FTP Server
==================

Public directory for file sharing.

Internal Network Subnet: 192.168.1.0/24
Admin Server: admin.cyberlab.local (192.168.1.30)
File Server: file-share.cyberlab.local (192.168.1.30)

For internal access to sensitive files, contact admin@cyberlab.local
Default credentials: See deployment notes in admin directory
EOF

cat > /var/ftp/admin/deployment-notes.txt << 'EOF'
=== CyberLab Internal Deployment Notes ===
Date: 2024-01-15
Deployed by: Lab Admin

SYSTEM PASSWORDS (For Lab Restoration Only):
- Windows Server Admin: AdminPass123!
- Windows Workstation: UserPass456
- IoT BMC Console: CyberLab@123
- Database: cyberlab_db_pass_789

DATABASE ACCESS:
- Server: 192.168.1.30:5432
- Database: cyberlab_prod
- User: dataadmin
- Password: dataadmin_pass_999

CREDENTIAL REUSE WARNING:
Note: Some credentials are reused across systems for ease of lab management.
This is intentional for demonstrating credential compromise risk.

INTERNAL SERVICES:
- SMB Share: \\server.cyberlab.local\data
- Admin Console: https://admin.cyberlab.local:8443
- Backup Service: 192.168.1.30:9000

NETWORK DIAGRAM:
External (10.0.1.0/24) --[Firewall]-- Internal (192.168.1.0/24)
Entry Point: Linux Server (192.168.1.10)
EOF

# Set restricted permissions but make discoverable
chmod 644 /var/ftp/pub/README.txt
chmod 640 /var/ftp/admin/deployment-notes.txt
chown ftp:ftp /var/ftp/admin/deployment-notes.txt 2>/dev/null || true

# Start ProFTPD
service proftpd start || proftpd -n 2>/dev/null &
sleep 2
echo "[LINUX-SERVER] ProFTPD service started on port 21"

# ============================================================================
# SECONDARY NETWORK INTERFACE CONFIGURATION
# ============================================================================
# This is critical: Linux server has access to internal network
# Students must discover this through enumeration
echo "[LINUX-SERVER] Configuring secondary network interface (eth1)..."

# eth1 is connected to internal network
if ip link show eth1 >/dev/null 2>&1; then
    ip addr add 192.168.1.10/24 dev eth1 2>/dev/null || true
    ip link set eth1 up 2>/dev/null || true
    echo "[LINUX-SERVER] Secondary interface eth1 configured on 192.168.1.10"
    echo "[LINUX-SERVER] This internal network is NOT directly accessible from external network"
    echo "[LINUX-SERVER] Students must discover this interface through post-exploitation enumeration"
else
    echo "[LINUX-SERVER] Note: eth1 not available in this environment"
fi

# ============================================================================
# DNS SERVICE
# ============================================================================
echo "[LINUX-SERVER] Starting local DNS cache..."
dnsmasq --conf-file=/etc/dnsmasq.conf &
sleep 1
echo "[LINUX-SERVER] DNS service available on port 53"

# ============================================================================
# PACKET CAPTURE FOR ANALYSIS
# ============================================================================
echo "[LINUX-SERVER] Starting packet capture for student analysis..."
mkdir -p /var/log/cyberlab/pcap
# Run tcpdump in background, capture interesting traffic
tcpdump -i any -w /var/log/cyberlab/pcap/traffic.pcap \
    'tcp port 22 or tcp port 21 or tcp port 80 or tcp port 443 or udp port 53' \
    2>/dev/null &
echo "[LINUX-SERVER] Packet capture running (accessible for student analysis)"

# ============================================================================
# SECURITY CONFIGURATIONS
# ============================================================================
echo "[LINUX-SERVER] Applying security configurations..."

# Enable core dumps for debugging
ulimit -c unlimited

# Create log files
touch /var/log/cyberlab/auth.log
touch /var/log/cyberlab/service.log
chmod 644 /var/log/cyberlab/*.log

# ============================================================================
# INTENTIONAL VULNERABILITIES AND MISCONFIGURATIONS
# ============================================================================
echo "[LINUX-SERVER] Configuring intentional learning scenarios..."

# 1. Verbose service banners (Finding 03)
cat > /etc/ssh/banner.txt << 'EOF'
========================================
  CyberLab SSH Server v7.4p1 (Ubuntu)
  Last login: never
========================================
EOF

# 2. ProFTPD version disclosure (Finding 03)
# ProFTPD is configured to show version in MOTD and server response

# 3. Outdated web application (Finding 04)
# Deployed old version with known vulnerability

# 4. HTML comments with information disclosure
cat >> /var/www/html/index.html << 'EOF'

<!-- Development note: Database migration from db-01 to db-02 in progress -->
<!-- TODO: Remove admin test account 'testuser' after deployment -->
<!-- Internal network: 192.168.1.0/24 - Firewall blocks ICMP for some hosts -->
<!-- Contact: infrastructure@cyberlab.local for access requests -->
EOF

# 5. robots.txt information disclosure (Finding 02)
cat > /var/www/html/robots.txt << 'EOF'
User-agent: *
Disallow: /admin/
Disallow: /internal/
Disallow: /backup/
Disallow: /config/

# TODO: Remove this line before production
# Temporary access: /sensitive/deployment-docs/
EOF

# 6. Unnecessary services running
# Services beyond the requirements are intentionally running for learning

# ============================================================================
# HEALTH CHECK
# ============================================================================
echo "[LINUX-SERVER] Running health checks..."

# Verify critical services
curl -f http://localhost/ > /dev/null 2>&1 && echo "[LINUX-SERVER] HTTP service: OK" || echo "[LINUX-SERVER] WARNING: HTTP failed"
nc -z localhost 21 2>/dev/null && echo "[LINUX-SERVER] FTP service: OK" || echo "[LINUX-SERVER] WARNING: FTP failed"
nc -z localhost 22 2>/dev/null && echo "[LINUX-SERVER] SSH service: OK" || echo "[LINUX-SERVER] WARNING: SSH failed"

# Signal health for docker-compose
touch /tmp/firewall-healthy
echo "[LINUX-SERVER] Health check complete - marking as ready"

# ============================================================================
# STARTUP COMPLETE
# ============================================================================
echo "[LINUX-SERVER] =========================================="
echo "[LINUX-SERVER] Linux Server ready for student access"
echo "[LINUX-SERVER] Services running:"
echo "[LINUX-SERVER]   - SSH (22)"
echo "[LINUX-SERVER]   - HTTP (80) / HTTPS (443)"
echo "[LINUX-SERVER]   - FTP (21)"
echo "[LINUX-SERVER]   - DNS (53)"
echo "[LINUX-SERVER] =========================================="
echo "[LINUX-SERVER] Waiting for connections..."

# Keep container running
tail -f /dev/null &
wait $!
