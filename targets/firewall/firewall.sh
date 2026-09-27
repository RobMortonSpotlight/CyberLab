#!/bin/bash
set -e

echo "[FIREWALL] Initializing CyberLab Firewall/Router..."

# Enable IP forwarding (may fail on restricted systems)
sysctl -w net.ipv4.ip_forward=1 2>/dev/null || true
sysctl -w net.ipv4.conf.all.send_redirects=0 2>/dev/null || true

echo "[FIREWALL] Configuring network interfaces..."
# Ensure interfaces are up
ip link set eth0 up 2>/dev/null || true
ip link set eth1 up 2>/dev/null || true

# Configure DNS
echo "[FIREWALL] Starting DNS service..."
dnsmasq --conf-file=/etc/dnsmasq.conf &
DNS_PID=$!
sleep 2

echo "[FIREWALL] Applying iptables rules..."
# Initialize iptables
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Set default policies
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# ============================================================================
# CRITICAL LEARNING SCENARIO: ICMP FILTERING
# ============================================================================
# Block ICMP echo requests (ping) to specific hosts to create learning scenario
# where students discover that "no ping response" doesn't mean "host doesn't exist"

echo "[FIREWALL] Configuring ICMP filtering (Learning Scenario)..."

# Block ICMP echo requests to Windows Server (192.168.1.30)
# Students must learn alternative discovery methods
iptables -A FORWARD -d 192.168.1.30 -p icmp --icmp-type echo-request -j DROP
iptables -A INPUT -d 192.168.1.30 -p icmp --icmp-type echo-request -j DROP

# Block ICMP echo requests to IoT device (192.168.1.50)
iptables -A FORWARD -d 192.168.1.50 -p icmp --icmp-type echo-request -j DROP
iptables -A INPUT -d 192.168.1.50 -p icmp --icmp-type echo-request -j DROP

# Allow ICMP echo replies and other ICMP types
iptables -A FORWARD -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type time-exceeded -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type destination-unreachable -j ACCEPT

# Allow ICMP to Linux server (should be discoverable normally)
iptables -A FORWARD -d 192.168.1.10 -p icmp --icmp-type echo-request -j ACCEPT

# ============================================================================
# TCP SERVICE ROUTING
# ============================================================================
# Allow TCP traffic to reach internal services
echo "[FIREWALL] Enabling TCP service routing..."

# SSH to Linux server
iptables -A FORWARD -d 192.168.1.10 -p tcp --dport 22 -j ACCEPT
iptables -A FORWARD -s 192.168.1.10 -p tcp --sport 22 -j ACCEPT

# HTTP/HTTPS to Linux server
iptables -A FORWARD -d 192.168.1.10 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -d 192.168.1.10 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 192.168.1.10 -p tcp --sport 80 -j ACCEPT
iptables -A FORWARD -s 192.168.1.10 -p tcp --sport 443 -j ACCEPT

# FTP to Linux server
iptables -A FORWARD -d 192.168.1.10 -p tcp --dport 21 -j ACCEPT
iptables -A FORWARD -d 192.168.1.10 -p tcp --dport 20 -j ACCEPT
iptables -A FORWARD -s 192.168.1.10 -p tcp --sport 20:21 -j ACCEPT

# SMB to Windows systems (blocked from external, allowed internally)
iptables -A FORWARD -d 192.168.1.0/24 -p tcp --dport 445 -j ACCEPT
iptables -A FORWARD -d 192.168.1.0/24 -p tcp --dport 139 -j ACCEPT

# RPC to Windows systems
iptables -A FORWARD -d 192.168.1.0/24 -p tcp --dport 135 -j ACCEPT
iptables -A FORWARD -d 192.168.1.0/24 -p tcp --dport 445 -j ACCEPT

# DNS
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p tcp --dport 53 -j ACCEPT

# ============================================================================
# NETWORK SEGMENTATION
# ============================================================================
# Block direct communication from external to internal network
# (except through specific paths)
echo "[FIREWALL] Enforcing network segmentation..."

# Once inside (via Linux server), allow internal communication
iptables -A FORWARD -s 192.168.1.0/24 -d 192.168.1.0/24 -j ACCEPT
iptables -A FORWARD -s 10.0.1.0/24 -d 192.168.1.0/24 -p tcp --dport 21 -j ACCEPT
iptables -A FORWARD -s 10.0.1.0/24 -d 192.168.1.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s 10.0.1.0/24 -d 192.168.1.0/24 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -s 10.0.1.0/24 -d 192.168.1.0/24 -p tcp --dport 22 -j ACCEPT

# Block everything else
iptables -A FORWARD -j DROP

# ============================================================================
# NAT CONFIGURATION
# ============================================================================
echo "[FIREWALL] Configuring NAT..."

# NAT for traffic from external to internal
iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -d 192.168.1.0/24 -j MASQUERADE

# Port forwarding for specific services (if needed)
# iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 8022 -j DNAT --to-destination 192.168.1.10:22

# ============================================================================
# LOGGING FOR ANALYSIS
# ============================================================================
echo "[FIREWALL] Enabling packet logging..."

# Log blocked ICMP (for student analysis)
iptables -A FORWARD -p icmp -j LOG --log-prefix "BLOCKED_ICMP: " --log-level 4

# Save iptables rules to persistent storage
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

echo "[FIREWALL] Firewall rules applied successfully"
echo "[FIREWALL] Configuration complete"

# Signal health check
touch /tmp/firewall-healthy

# Keep container running
echo "[FIREWALL] Firewall/Router active and monitoring traffic..."
tail -f /dev/null &
wait $!
