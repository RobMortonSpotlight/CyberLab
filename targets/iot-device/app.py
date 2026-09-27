#!/usr/bin/env python3
"""
CyberLab IoT Device Simulation - IPMI/BMC Console
Simulates a Baseboard Management Controller (BMC) for learning purposes.
Intentionally includes security weaknesses for educational scenarios.
"""

import os
import logging
import json
from datetime import datetime
from flask import Flask, render_template_string, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# Configuration from environment
DEVICE_ID = os.getenv('DEVICE_ID', 'bmc-lab-01')
DEFAULT_USER = os.getenv('DEFAULT_USER', 'admin')
DEFAULT_PASS = os.getenv('DEFAULT_PASS', 'CyberLab@123')

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/cyberlab/iot-device.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# ============================================================================
# Finding 15: IoT Default Credentials
# Default lab credentials that students discover through reconnaissance
# ============================================================================
VALID_CREDENTIALS = {
    'admin': 'CyberLab@123',
    'root': 'CyberLab@123',
    'test': 'test123'
}

# Session storage (simplified for lab)
active_sessions = {}

# ============================================================================
# IPMI SIMULATION DATA
# ============================================================================
SYSTEM_INFO = {
    'manufacturer': 'CyberLab',
    'model': 'Lab BMC 2000',
    'firmware_version': '2.45.10',
    'ipmi_version': '2.0',
    'device_id': DEVICE_ID,
    'serial_number': 'LAB-2024-001',
    'mac_address': '00:11:22:33:44:55'
}

SENSOR_DATA = {
    'temperature': 45.2,
    'voltage': 12.0,
    'fan_speed': 3200,
    'power_status': 'OK',
    'system_status': 'Running'
}

# ============================================================================
# WEB INTERFACE (Finding 14: Exposed Management Interface)
# ============================================================================
HTML_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
    <title>CyberLab IPMI Console</title>
    <style>
        body { font-family: monospace; background: #1a1a1a; color: #0f0; margin: 20px; }
        .banner { border: 1px solid #0f0; padding: 10px; margin: 10px 0; }
        .info { background: #0a0a0a; padding: 10px; margin: 10px 0; border: 1px solid #0f0; }
        .section { margin: 20px 0; }
        .alert { color: #f00; font-weight: bold; }
        form { margin: 10px 0; }
        input, button { background: #0a0a0a; color: #0f0; border: 1px solid #0f0; padding: 5px; }
        button { cursor: pointer; }
    </style>
</head>
<body>
    <div class="banner">
        <h1>CyberLab IPMI Baseboard Management Console</h1>
        <p>Device: {{ device_id }} | Firmware: {{ firmware_version }}</p>
    </div>

    <div class="info">
        <h2>System Status</h2>
        <p>Status: <span class="alert">{{ system_status }}</span></p>
        <p>Temperature: {{ temperature }}°C</p>
        <p>Power: {{ power_status }}</p>
        <p>Serial: {{ serial_number }}</p>
    </div>

    <div class="section">
        <h2>Management Console Access</h2>
        <p>The management interface is accessible from the internal network.</p>
        <p>Finding 14: This interface should not be exposed to untrusted networks.</p>
    </div>

    <div class="section">
        <h2>Default Credentials (Finding 15)</h2>
        <p>This device uses default credentials as configured in the lab.</p>
        <p>
            <form method="post" action="/api/login">
                <input type="text" name="username" placeholder="Username" value="{{ username }}">
                <input type="password" name="password" placeholder="Password">
                <button type="submit">Login</button>
            </form>
        </p>
        <!-- Finding 02: Information Disclosure -->
        <!-- Default credentials: admin / CyberLab@123 -->
        <!-- Used across lab systems for learning credential reuse scenario -->
    </div>

    <div class="info">
        <h2>Network Configuration</h2>
        <p>IP Address: 192.168.1.50</p>
        <p>MAC Address: {{ mac_address }}</p>
        <p>Subnet: 192.168.1.0/24 (Internal Network)</p>
        <p>Gateway: 192.168.1.1 (Firewall)</p>

        <p><strong>Finding 01:</strong> This device does not respond to ICMP (ping)</p>
        <p>Use alternative discovery: nmap -Pn</p>
    </div>

    <div class="info">
        <h2>IPMI Services</h2>
        <p>IPMI LAN Interface (Port 623/UDP)</p>
        <p>Redfish Management API (Port 8080)</p>
        <p>Web Interface (This page - Port 80)</p>
        <p>VNC Console (Port 5900)</p>
    </div>

    <hr>
    <p style="color: #666;">CyberLab Learning Environment | IPMI Simulation</p>
</body>
</html>
'''

# ============================================================================
# API ENDPOINTS
# ============================================================================

@app.route('/', methods=['GET'])
def index():
    """Main management interface"""
    return render_template_string(
        HTML_TEMPLATE,
        device_id=SYSTEM_INFO['device_id'],
        firmware_version=SYSTEM_INFO['firmware_version'],
        system_status=SENSOR_DATA['system_status'],
        temperature=SENSOR_DATA['temperature'],
        power_status=SENSOR_DATA['power_status'],
        serial_number=SYSTEM_INFO['serial_number'],
        mac_address=SYSTEM_INFO['mac_address'],
        username='admin'
    )

@app.route('/api/login', methods=['POST'])
def login():
    """
    Finding 15: Default Credentials Access Point
    Students should discover these credentials through enumeration
    """
    username = request.form.get('username', '')
    password = request.form.get('password', '')

    logger.info(f"Login attempt: {username}")

    # Finding 15: Weak authentication check
    if username in VALID_CREDENTIALS and VALID_CREDENTIALS[username] == password:
        session_id = f"SESSION-{datetime.now().timestamp()}"
        active_sessions[session_id] = {
            'user': username,
            'timestamp': datetime.now().isoformat(),
            'authenticated': True
        }
        logger.info(f"Login successful: {username}")
        return jsonify({
            'success': True,
            'message': f'Successfully logged in as {username}',
            'session_id': session_id
        })
    else:
        logger.warning(f"Failed login attempt: {username}")
        return jsonify({
            'success': False,
            'message': 'Invalid credentials'
        }), 401

@app.route('/api/system/info', methods=['GET'])
def system_info():
    """
    Finding 03: Service Banner Disclosure
    Expose system information for version fingerprinting
    """
    return jsonify({
        'device': SYSTEM_INFO,
        'sensors': SENSOR_DATA,
        'firmware_vulnerable': True,  # Finding 04: Outdated firmware
        'vulnerability_cve': ['CVE-2023-XXXX', 'CVE-2023-YYYY']
    })

@app.route('/api/system/status', methods=['GET'])
def system_status():
    """System status endpoint"""
    return jsonify({
        'status': SENSOR_DATA['system_status'],
        'power': SENSOR_DATA['power_status'],
        'temperature': SENSOR_DATA['temperature'],
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/network/config', methods=['GET'])
def network_config():
    """
    Finding 09: SMB Information Exposure equivalent for IPMI
    Expose network topology information
    """
    return jsonify({
        'hostname': DEVICE_ID,
        'ip_address': '192.168.1.50',
        'mac_address': SYSTEM_INFO['mac_address'],
        'subnet': '192.168.1.0/24',
        'gateway': '192.168.1.1',
        'dns_servers': ['192.168.1.1', '8.8.8.8'],
        'network_segment': 'internal_management',
        'note': 'This network segment is initially inaccessible from external position'
    })

@app.route('/api/users', methods=['GET'])
def list_users():
    """
    Finding 15: IoT Default Credentials
    Expose user list with credential hints
    """
    return jsonify({
        'users': [
            {
                'username': 'admin',
                'role': 'Administrator',
                'enabled': True,
                'default_credential': True
            },
            {
                'username': 'root',
                'role': 'Superuser',
                'enabled': True,
                'default_credential': True
            },
            {
                'username': 'test',
                'role': 'Test Account',
                'enabled': True,
                'default_credential': True
            }
        ],
        'note': 'Finding 15: Default credentials are configured in this lab device'
    })

@app.route('/api/logs', methods=['GET'])
def logs():
    """
    Finding 11: Authentication Exposure
    Show authentication logs (intentionally cleartext)
    """
    return jsonify({
        'recent_events': [
            {
                'timestamp': '2024-01-15 09:45:00',
                'event': 'User admin logged in from 192.168.1.10',
                'severity': 'info'
            },
            {
                'timestamp': '2024-01-15 08:30:00',
                'event': 'System power cycle initiated by root',
                'severity': 'notice'
            },
            {
                'timestamp': '2024-01-14 02:00:00',
                'event': 'Automatic backup executed',
                'severity': 'info'
            }
        ]
    })

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy'}), 200

# ============================================================================
# ERROR HANDLING
# ============================================================================

@app.errorhandler(404)
def not_found(error):
    """
    Finding 03: Detailed Error Messages
    Intentionally verbose error information
    """
    return jsonify({
        'error': 'Not Found',
        'message': f'The requested resource was not found',
        'path': request.path,
        'method': request.method
    }), 404

@app.errorhandler(500)
def internal_error(error):
    """
    Finding 03: Excessive Application Error Information
    Leak stack traces for learning purposes
    """
    return jsonify({
        'error': 'Internal Server Error',
        'message': str(error),
        'traceback': 'Internal error occurred'
    }), 500

# ============================================================================
# STARTUP
# ============================================================================

if __name__ == '__main__':
    logger.info(f"CyberLab IoT Device ({DEVICE_ID}) starting...")
    logger.info(f"Default credentials: {DEFAULT_USER} / {DEFAULT_PASS}")
    logger.info("This is an intentional learning scenario with security weaknesses")

    # Run Flask app
    app.run(
        host='0.0.0.0',
        port=8080,
        debug=False,
        threaded=True
    )
