#!/bin/bash

echo "[SSH] Configuring SSH service..."

# Create SSH keys if they don't exist
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "[SSH] Generating RSA keys..."
    ssh-keygen -A
fi

# Configure SSH daemon
cat > /etc/ssh/sshd_config << 'EOF'
# SSH Server Configuration for CyberLab
Port 22
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

# Finding 03: Service Banner Disclosure
# Intentionally verbose banner for learning scenarios
Banner /etc/ssh/banner.txt

# Authentication
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
PermitEmptyPasswords no

# Keep-alive
TCPKeepAlive yes
ClientAliveInterval 300
ClientAliveCountMax 2

# Logging (for analysis)
SyslogFacility AUTH
LogLevel VERBOSE

# Finding 13: Excessive Privileges
# Allow very permissive access for lab learning
AllowUsers *
AllowGroups *
MaxAuthTries 10

# X11 forwarding allowed (Intentional)
X11Forwarding yes
X11UseLocalhost no

# Allow port forwarding (for learning)
AllowAgentForwarding yes
AllowTcpForwarding yes

# Finding 02: Excessive Service Exposure
# Multiple subsystems exposed
Subsystem sftp /usr/lib/openssh/sftp-server

# Accept locale-related environment variables
AcceptEnv LANG LC_*

# Match blocks for specific users (with weak credentials)
Match User studentlab
    AllowUsers studentlab
    PasswordAuthentication yes
EOF

# Create banner file
cat > /etc/ssh/banner.txt << 'EOF'
========================================
   CyberLab SSH Server v7.4p1
   Ubuntu Linux 22.04 LTS
   Last login: 2024-01-15 09:45 from 192.168.1.50
========================================
EOF

# Set proper permissions
chmod 644 /etc/ssh/sshd_config
chmod 644 /etc/ssh/banner.txt

echo "[SSH] SSH configuration complete"
