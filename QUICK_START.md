# CyberLab - Quick Start Guide

## Status

The Docker Compose setup has been created but requires network access to download packages. Due to network constraints in the build environment, we've created:

✅ **Complete Lab Design** - All infrastructure as code
✅ **Java Controller** - Built and ready (JAR compiled)
✅ **Configuration Files** - All 5 targets configured  
✅ **Documentation** - Complete learning guide

## How to Deploy on Your System

### Prerequisites
- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- Docker Compose
- Network access to Docker Hub and package mirrors
- 4GB+ RAM

### Step 1: Clone/Copy the Lab

```bash
cd /Users/robertmorton/cyberlab
```

### Step 2: Start Docker

**macOS/Windows:**
```bash
open /Applications/Docker.app
# or start Docker Desktop manually
```

**Linux:**
```bash
sudo systemctl start docker
```

### Step 3: Deploy

```bash
docker-compose up -d
```

This will:
- Build all 6 images (firewall, Linux, Windows WS, Windows Server, IoT, Lab Controller)
- Start all services
- Configure networks and firewall rules
- Launch the management API

### Step 4: Access the Lab

Once running:

```bash
# Check status
docker-compose ps

# View lab health
curl http://localhost:8080/api/health

# See all targets
curl http://localhost:8080/api/targets

# View lab status
curl http://localhost:8080/api/lab/status
```

### Step 5: Start Learning

From your student position (10.0.1.100):

```bash
# Basic host discovery
nmap -sn 10.0.1.0/24

# Comprehensive scan
nmap -p- 10.0.1.10

# When ICMP fails
nmap -Pn 192.168.1.0/24

# Service enumeration
nmap -sV 10.0.1.10
```

## Files Included

### Configuration
- `docker-compose.yml` - Complete orchestration
- README.md - Full documentation

### Targets
1. **Firewall/Router** - `targets/firewall/`
2. **Linux Server** - `targets/linux-server/`
3. **Windows Workstation** - `targets/windows-workstation/`
4. **Windows Server** - `targets/windows-server/`
5. **IoT Device** - `targets/iot-device/`

### Lab Controller
- `lab-controller/` - REST API management system
- `lab-controller/build/libs/cyberlab-controller-1.0.0.jar` - Compiled JAR

## Architecture

```
External (10.0.1.0/24)
    ↓
Firewall [ICMP blocks to .30 and .50]
    ↓
Internal (192.168.1.0/24)
├─ Linux Server 192.168.1.10 [Entry point]
├─ Windows WS 192.168.1.20
├─ Windows Server 192.168.1.30
└─ IoT Device 192.168.1.50
```

## Troubleshooting

### Containers won't start
```bash
# Check Docker
docker ps

# View logs
docker-compose logs firewall
docker-compose logs linux-server

# Rebuild everything
docker-compose down -v
docker-compose up -d --build
```

### Connection refused
- Wait 30 seconds for services to fully start
- Verify docker network: `docker network ls`
- Check connectivity: `docker-compose exec firewall ping -c1 192.168.1.10`

### Port already in use
```bash
# Find what's using port 8080
lsof -i :8080

# Use different port mapping
docker-compose down
# Edit docker-compose.yml, change "8080:8080" to "8081:8080"
docker-compose up -d
```

## Lab Features

✅ 5 interconnected systems
✅ ICMP filtering teaches alternative discovery
✅ Vulnerable ProFTPD for exploitation
✅ Hidden internal network (post-exploitation)
✅ SMB information leakage
✅ IPMI/BMC with default credentials
✅ Credential reuse across systems
✅ REST API for status and validation
✅ Packet capture for analysis
✅ 16+ intentional security findings

## Learning Outcomes

After completing this lab, students will understand:

1. **Network Reconnaissance**
   - ICMP-based vs TCP-based discovery
   - Why ping doesn't always work
   - Service enumeration and fingerprinting

2. **Vulnerability Analysis**
   - Version identification
   - CVE research
   - Exploitation methodology

3. **Access Control**
   - Lateral movement via credentials
   - Weak authentication
   - Privilege escalation

4. **Evidence Preservation**
   - Packet capture analysis
   - Traffic filtering
   - Proof of compromise

## Support

For issues:
1. Check Docker daemon is running
2. Verify network connectivity
3. Review docker-compose logs
4. Check README.md for detailed documentation

---

**CyberLab Version 1.0** - Educational Security Lab
Deploy with: `docker-compose up -d`
