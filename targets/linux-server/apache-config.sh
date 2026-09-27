#!/bin/bash

echo "[APACHE] Configuring Apache web server..."

# Create necessary directories
mkdir -p /var/www/html/admin
mkdir -p /var/www/html/internal
mkdir -p /var/www/html/backup
mkdir -p /var/www/html/config

# Create main index page with intentional information disclosure
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>CyberLab Internal Portal</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f0f0f0; }
        h1 { color: #0173B2; }
        .info { background: white; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .warning { color: #d32f2f; font-weight: bold; }
    </style>
</head>
<body>
    <h1>CyberLab Internal Portal</h1>

    <div class="info">
        <h2>System Information</h2>
        <p>Server: linux-server.cyberlab.local</p>
        <p>Version: Ubuntu 22.04 LTS</p>
        <p>Apache: Apache/2.4.41</p>
        <p>PHP: 7.4.3</p>
    </div>

    <div class="info">
        <h2>Available Services</h2>
        <ul>
            <li><a href="/admin/">Admin Dashboard</a> (Requires Authentication)</li>
            <li><a href="/internal/">Internal Documentation</a></li>
            <li><a href="/backup/">Backup Status</a></li>
            <li><a href="robots.txt">Site Map</a></li>
        </ul>
    </div>

    <div class="info">
        <h2>Network Information</h2>
        <p><span class="warning">FINDING:</span> This server has access to internal network:</p>
        <p>Internal Subnet: 192.168.1.0/24</p>
        <p>Gateway: 192.168.1.1</p>
        <p>Internal Services:</p>
        <ul>
            <li>File Server: 192.168.1.30 (SMB)</li>
            <li>Workstation: 192.168.1.20 (SMB)</li>
            <li>Management Device: 192.168.1.50 (IPMI)</li>
        </ul>
    </div>

    <!-- FINDING 02: Information Disclosure in Comments -->
    <!-- Development note: Database migration from db-01 to db-02 in progress -->
    <!-- TODO: Remove admin test account 'testuser' after deployment -->
    <!-- Internal network: 192.168.1.0/24 - Firewall blocks ICMP for some hosts -->
    <!-- Contact: infrastructure@cyberlab.local for access requests -->
    <!-- Default credentials for testing: admin/admin123 (REMOVE BEFORE PRODUCTION) -->

    <hr>
    <p style="color: #666; font-size: 0.9em;">CyberLab Learning Environment | Last Updated: 2024-01-15</p>
</body>
</html>
EOF

# Create admin page with weak authentication
cat > /var/www/html/admin/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Admin Dashboard</title>
</head>
<body>
    <h1>Administrator Dashboard</h1>

    <h2>System Status</h2>
    <p>All systems operational</p>

    <h2>Recent Activity</h2>
    <ul>
        <li>Database backup: 2024-01-15 02:00</li>
        <li>System update: 2024-01-14 18:30</li>
        <li>User 'dataadmin' accessed at 192.168.1.30</li>
    </ul>

    <!-- FINDING: Exposed credentials in comments -->
    <!-- SSH: ssh -u dataadmin@192.168.1.30 (use cyberlab_db_pass_789) -->
    <!-- SMB: \\server.cyberlab.local\data (credentials below) -->
    <!-- Windows Admin: AdminPass123! -->

    <p><strong>This is a restricted area</strong></p>
</body>
</html>
EOF

# Create internal documentation page
cat > /var/www/html/internal/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Internal Documentation</title>
</head>
<body>
    <h1>Internal Documentation</h1>

    <h2>Network Topology</h2>
    <pre>
External Network (10.0.1.0/24):
  - Student workstation: 10.0.1.100
  - Firewall/Gateway: 10.0.1.1

Internal Network (192.168.1.0/24):
  - Firewall/Router: 192.168.1.1
  - Linux Server (this host): 192.168.1.10
  - Windows Workstation: 192.168.1.20
  - Windows Server: 192.168.1.30
  - IoT Device (BMC): 192.168.1.50
    </pre>

    <h2>Service Endpoints</h2>
    <ul>
        <li>SMB Share: \\server.cyberlab.local\data (Port 445)</li>
        <li>Database: 192.168.1.30:5432</li>
        <li>Web Admin: https://admin.cyberlab.local:8443</li>
        <li>Backup Service: 192.168.1.30:9000</li>
    </ul>
</body>
</html>
EOF

# Create backup status page
mkdir -p /var/www/html/backup
cat > /var/www/html/backup/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Backup Status</title>
</head>
<body>
    <h1>Backup Status</h1>
    <p>Last backup: 2024-01-15 02:00 UTC</p>
    <p>Status: SUCCESS</p>
    <p>Location: /backup/db-2024-01-15.sql.gz</p>
</body>
</html>
EOF

# Create health check endpoint
cat > /var/www/html/health << 'EOF'
OK
EOF

# Configure Apache modules and virtual hosts
cat > /etc/apache2/sites-enabled/000-default.conf << 'EOF'
<VirtualHost *:80>
    ServerName linux-server.cyberlab.local
    ServerAdmin admin@cyberlab.local

    DocumentRoot /var/www/html

    # Finding 03: Detailed error messages (Information disclosure)
    ErrorDocument 404 "The requested resource was not found on this server"

    # Logging
    CustomLog ${APACHE_LOG_DIR}/access.log combined
    ErrorLog ${APACHE_LOG_DIR}/error.log

    # Finding 02: Unnecessary modules and services
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Create SSL certificate for HTTPS
echo "[APACHE] Generating self-signed SSL certificate..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/server.key \
    -out /etc/ssl/certs/server.crt \
    -subj "/CN=linux-server.cyberlab.local" 2>/dev/null || true

# Enable SSL site
cat > /etc/apache2/sites-enabled/000-default-ssl.conf << 'EOF'
<VirtualHost *:443>
    ServerName linux-server.cyberlab.local

    DocumentRoot /var/www/html

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/server.crt
    SSLCertificateKeyFile /etc/ssl/private/server.key

    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Enable necessary Apache modules
a2enmod ssl 2>/dev/null || true
a2enmod rewrite 2>/dev/null || true

# Disable default Apache page
rm -f /etc/apache2/sites-enabled/000-default.conf 2>/dev/null || true

echo "[APACHE] Configuration complete"
