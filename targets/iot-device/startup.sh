#!/bin/bash
set -e

echo "[IoT-DEVICE] CyberLab Management Device (IPMI/BMC Simulation) starting..."
echo "[IoT-DEVICE] Device ID: $DEVICE_ID"
echo "[IoT-DEVICE] Role: Baseboard Management Controller (BMC) Simulation"

# Create log directories
mkdir -p /var/log/cyberlab

# Note: ICMP is blocked by firewall
echo "[IoT-DEVICE] Note: This device does not respond to ICMP (ping)"
echo "[IoT-DEVICE] Students must use: nmap -Pn or direct port scanning"

# ============================================================================
# START WEB HTTP SERVER (Python built-in)
# ============================================================================
echo "[IoT-DEVICE] Starting management web interface..."
echo "[IoT-DEVICE] Listening on port 8080"

# Create a simple HTTP response
mkdir -p /tmp/iot-www
cat > /tmp/iot-www/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>CyberLab IPMI Console</title>
    <style>
        body { font-family: monospace; background: #1a1a1a; color: #0f0; margin: 20px; }
        .banner { border: 1px solid #0f0; padding: 10px; }
        .info { background: #0a0a0a; padding: 10px; margin: 10px 0; border: 1px solid #0f0; }
    </style>
</head>
<body>
    <div class="banner">
        <h1>CyberLab IPMI Baseboard Management Console</h1>
    </div>
    <div class="info">
        <h2>System Status</h2>
        <p>Device: bmc-lab-01</p>
        <p>Status: Running</p>
        <p>Default User: admin</p>
        <p>Default Pass: CyberLab@123</p>
        <!-- Finding 15: Default credentials exposed -->
        <!-- Used across lab systems for credential reuse scenario -->
    </div>
</body>
</html>
EOF

# Start Python HTTP server
cd /tmp/iot-www
python3 -m http.server 8080 > /var/log/cyberlab/http.log 2>&1 &
HTTP_PID=$!
echo $HTTP_PID > /var/run/http.pid
sleep 2

echo "[IoT-DEVICE] Web interface started on port 8080"

# ============================================================================
# SIMULATED IPMI LAN INTERFACE
# ============================================================================
echo "[IoT-DEVICE] IPMI LAN Interface (Port 623/UDP) - SIMULATED"
echo "[IoT-DEVICE] Finding 07: IPMI/BMC Authentication Exposure"

# Simulate IPMI port listening
(while true; do echo "IPMI_OK" | nc -l -u -p 623 2>/dev/null || true; sleep 1; done) &
echo "[IoT-DEVICE] IPMI service listening on UDP port 623"

# ============================================================================
# SECURITY FINDINGS
# ============================================================================
echo "[IoT-DEVICE] Configuring security findings..."
echo "[IoT-DEVICE] Finding 15: IoT Default Credentials (admin/CyberLab@123)"
echo "[IoT-DEVICE] Finding 14: Exposed Management Interface (http://192.168.1.50:8080)"
echo "[IoT-DEVICE] Finding 07: IPMI Authentication Exposure (port 623)"

# Packet capture
if command -v tcpdump &> /dev/null; then
    tcpdump -i any -w /var/log/cyberlab/ipmi-traffic.pcap 'port 623 or port 8080' 2>/dev/null &
fi

# Signal health
touch /tmp/ipmi-healthy

# ============================================================================
# STARTUP COMPLETE
# ============================================================================
echo "[IoT-DEVICE] =========================================="
echo "[IoT-DEVICE] IoT Management Device Ready"
echo "[IoT-DEVICE] Services:"
echo "[IoT-DEVICE]   - Web Console: http://192.168.1.50:8080"
echo "[IoT-DEVICE]   - IPMI: 192.168.1.50:623/UDP"
echo "[IoT-DEVICE] =========================================="

# Keep container running
wait $HTTP_PID
