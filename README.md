# CyberLab - Network Security Learning Environment

A comprehensive, realistic network security lab for teaching reconnaissance, enumeration, and vulnerability analysis through hands-on exploration.

## Quick Start

### Prerequisites
- Docker and Docker Compose
- 4GB+ RAM available
- Linux/macOS (Windows requires WSL2)

### Deploy the Lab

```bash
cd /Users/robertmorton/cyberlab
docker-compose up -d
```

### Verify Lab Status

```bash
# Check all services are running
docker-compose ps

# View lab controller health
curl http://localhost:8080/api/health

# Get lab status
curl http://localhost:8080/api/lab/status

# List all targets
curl http://localhost:8080/api/targets
```

### Access the Lab

**Lab Controller Dashboard:** http://localhost:8080

**Student Access Point:** 10.0.1.100 (configured in firewall)

**Internal Network:** 192.168.1.0/24 (not directly accessible initially)

## Network Architecture

```
External Network (10.0.1.0/24)
  └─ Student Position
      └─ Firewall/Router (10.0.1.1 / 192.168.1.1)
          ├─ Linux Server (192.168.1.10) [ICMP ALLOWED]
          │   ├─ SSH (22)
          │   ├─ HTTP/HTTPS (80/443)
          │   ├─ FTP (21) [VULNERABLE ProFTPD]
          │   └─ DNS (53)
          │
          ├─ Windows Workstation (192.168.1.20) [ICMP BLOCKED]
          │   ├─ SMB (445)
          │   └─ RPC (135)
          │
          ├─ Windows Server (192.168.1.30) [ICMP BLOCKED]
          │   ├─ SMB (445)
          │   ├─ RPC (135)
          │   └─ PostgreSQL (5432)
          │
          └─ IoT Device (192.168.1.50) [ICMP BLOCKED]
              ├─ Web Console (8080)
              ├─ IPMI (623)
              └─ VNC (5900)
```

## Lab Targets

### Target 1: Firewall / Router
- **IP:** 10.0.1.1 / 192.168.1.1
- **Role:** Gateway and network segmentation
- **Learning:** ICMP filtering, firewall behavior, alternative discovery
- **Findings:** F01

### Target 2: Linux Application Server
- **IP:** 10.0.1.10 (external) / 192.168.1.10 (internal)
- **Services:** SSH, HTTP/HTTPS, FTP, DNS
- **Vulnerabilities:** ProFTPD 1.3.5 (Finding 05), Information disclosure
- **Key Finding:** Hidden second interface to internal network
- **Findings:** F02, F03, F05, F06

### Target 3: Windows Workstation
- **IP:** 192.168.1.20
- **Services:** SMB, RPC, NTLM authentication
- **Role:** Typical employee workstation
- **Findings:** F09, F10, F11

### Target 4: Windows Server
- **IP:** 192.168.1.30
- **Services:** SMB, RPC, PostgreSQL, NTLM
- **Role:** Internal file server and administrative infrastructure
- **Findings:** F03, F08, F10, F12, F13, F14

### Target 5: IoT / Management Device
- **IP:** 192.168.1.50
- **Services:** IPMI simulation, Web console, VNC
- **Role:** Baseboard Management Controller (BMC)
- **Key:** Default credentials (Finding 15)
- **Findings:** F07, F14, F15

## Security Findings (16 Total)

### Introductory Level
- **F01:** ICMP Filtering - Firewall blocks ICMP to selected hosts
- **F02:** Excessive Service Exposure - Unnecessary services running
- **F03:** Detailed Service Banners - Version information disclosed

### Intermediate Level
- **F04:** Outdated Web Application - Known vulnerabilities in deployed software
- **F05:** Vulnerable ProFTPD - Controlled vulnerability for exploitation
- **F07:** IPMI/BMC Authentication Exposure - Management plane security
- **F09:** SMB Information Exposure - Windows network enumeration
- **F10:** Overly Permissive SMB Share - Contains deployment notes, credentials
- **F13:** Excessive Privileges - Service accounts with admin rights
- **F14:** Exposed Management Interface - Accessible from internal network
- **F15:** IoT Default Credentials - Admin / CyberLab@123
- **F16:** Cleartext Network Protocol - Unencrypted traffic

### Advanced Level
- **F06:** Hidden Internal Network - Second interface discovered post-exploitation
- **F08:** Credential Reuse - Same passwords across multiple systems
- **F11:** NTLM Authentication Exposure - Capturable in network traffic
- **F12:** Credential Reuse Scenario - Demonstrates lateral movement

## Learning Paths

### Primary Attack Chain
1. Initial network access from external position
2. ICMP discovery partially fails (firewall blocking)
3. Student recognizes filtering pattern
4. Alternative discovery using `nmap -Pn`
5. Linux server identified and enumerated
6. ProFTPD vulnerability identified via version research
7. Exploitation grants foothold access
8. Post-exploitation enumeration discovers second interface
9. Pivot to internal network via Linux server
10. Windows and IoT systems discovered
11. SMB and IPMI weaknesses identified
12. Credential chaining demonstrates attack propagation
13. Complete attack path documented

### Alternative Discovery Methods
- DNS enumeration reveals internal hosts
- Banner grabbing discloses software versions
- SMB enumeration from discovered systems
- Default credentials on management devices

## Key Learning Objectives

### Network Reconnaissance
- ICMP-based vs. TCP-based host discovery
- Service enumeration and fingerprinting
- Network topology discovery through enumeration
- Understanding the impact of firewall rules on scanning

### Vulnerability Research
- CVE lookup and analysis
- Version identification via banners and responses
- Exploitability assessment
- Proof-of-concept development

### Access Control
- SMB share enumeration and exploitation
- Credential reuse risks
- Lateral movement via credential chaining
- Management plane security

### Packet Analysis
- Capturing relevant network traffic
- Protocol-specific filtering (NTLM, SMB, DNS)
- Evidence preservation for reporting
- Understanding cleartext protocols

## API Endpoints

### Lab Management
```
GET  /api/health                      - Service health check
GET  /api/lab/status                  - Overall lab health
GET  /api/targets                     - List all lab targets
GET  /api/targets/{name}              - Target details and status
```

### Security Findings
```
GET  /api/findings                    - List all findings
GET  /api/findings/by-target/{name}   - Findings for specific target
POST /api/findings/validate/{id}      - Validate a finding
```

### Learning Resources
```
GET  /api/lab/topology                - Network topology details
GET  /api/lab/learning-paths          - Discovery chain documentation
GET  /api/lab/nmap-guide              - Nmap usage guide
GET  /api/lab/tcpdump-guide           - Packet capture guide
```

## Docker Compose Commands

### Start the lab
```bash
docker-compose up -d
```

### View logs
```bash
docker-compose logs -f                # All services
docker-compose logs -f linux-server   # Specific service
```

### Stop the lab
```bash
docker-compose down
```

### Reset the lab (complete restart)
```bash
docker-compose down -v
docker-compose up -d
```

### Access container shell
```bash
docker-compose exec linux-server bash
docker-compose exec windows-workstation bash
```

## Health Checks

Each target exposes health indicators:

```bash
# Linux Server
curl http://10.0.1.10/health

# Windows Server
curl -k https://192.168.1.30:8443/health

# IoT Device
curl http://192.168.1.50:8080/health

# Lab Controller
curl http://localhost:8080/api/health
```

## Student Instructions

### Initial Setup
1. Ensure you have network access to 10.0.1.100
2. Start with `nmap -sn 10.0.1.0/24`
3. Notice which hosts respond to ping

### Discovery Phase
1. Use `nmap -p- 10.0.1.10` for comprehensive port scan
2. Use `nmap -sV 10.0.1.10` to identify services
3. Try `nmap -Pn 192.168.1.0/24` when ICMP fails
4. Use `nmap --script smb-os-discovery` for SMB enumeration

### Exploitation Phase
1. Research ProFTPD 1.3.5 vulnerabilities
2. Gain foothold access to Linux server
3. Use post-exploitation enumeration to find second interface
4. Establish persistence on compromised system

### Internal Reconnaissance
1. Perform network enumeration from within
2. Identify Windows systems via SMB
3. Discover IoT device management interface
4. Enumerate SMB shares for credentials

### Evidence Collection
1. Capture SMB traffic with tcpdump
2. Record NTLM authentication attempts
3. Document credential discovery
4. Preserve proof of system access

## Student Deliverable Template

### Executive Reconnaissance and Vulnerability Summary

**Environment Discovered**
- List of network segments
- Topology observations
- Firewall behavior findings

**Important Hosts**
- IP addresses and roles
- Services per host
- Access methods

**Major Vulnerabilities**
- Specific CVEs discovered
- Exploitation methods
- Impact assessment

**Significant Misconfigurations**
- Credential reuse
- Excessive permissions
- Exposed management interfaces

**Evidence**
- Screenshots/command output
- Packet captures
- Log evidence

**Attack Path**
- Sequential steps taken
- Tools used
- Success indicators

**Recommended Remediation**
- Per-system fixes
- Overall improvements

## Mentor Guide

### Verbal Challenge Questions

1. "How do you know that host exists?"
2. "Why didn't your first scan identify it?"
3. "What evidence indicates a firewall is affecting your results?"
4. "How did you discover the second network?"
5. "How do you know this service is vulnerable rather than simply old?"
6. "What information allowed you to continue your reconnaissance?"
7. "Which two weaknesses became substantially more dangerous when combined?"
8. "What control would break this attack path?"

### Key Learning Moments

- ICMP vs. TCP-based discovery differences
- The importance of service banners for research
- Credential reuse as attack chain enabler
- Network segmentation bypass through pivoting
- Evidence-based reporting vs. speculation

## Troubleshooting

### Services not starting
```bash
# Check logs
docker-compose logs firewall
docker-compose logs linux-server

# Verify networking
docker network ls
docker network inspect cyberlab_external
```

### Connectivity issues
```bash
# From host to container
ping 10.0.1.1
nmap -p 22 10.0.1.10

# Between containers
docker-compose exec linux-server ping 192.168.1.30
docker-compose exec windows-server curl http://192.168.1.10
```

### Health checks failing
```bash
# Verify service
docker-compose exec linux-server curl localhost/health

# Check logs
docker-compose logs -f firewall
```

## Architecture Notes

### Lab Design Principles

1. **Progressive Complexity** - Findings are rated introductory, intermediate, advanced
2. **Evidence-Based Learning** - Students must use tools to prove discoveries
3. **Realistic Scenarios** - Network mimics real organizational structure
4. **Credential Chaining** - Weak credentials enable attack progression
5. **Network Segmentation** - Firewall creates learning opportunities
6. **Fault Tolerance** - System recoverable after student actions

### Educational Optimizations

- Intentional findings are deterministic and reproducible
- Multiple discovery paths available (not linear)
- Tools (nmap, tcpdump) reveal truth through evidence
- Firewa behavior creates "productive struggle"
- Students learn *why* reconnaissance matters

## Legal and Ethical Statement

This lab is designed for **authorized educational use only** in classroom or controlled training environments. All security weaknesses are intentional for learning purposes. This lab should never be deployed on live networks without explicit authorization.

## Support

For issues, questions, or contributions:
- Check existing documentation
- Review Docker Compose logs
- Verify network connectivity
- Confirm all services are healthy via `/api/lab/status`

---

**CyberLab Version 1.0**
**Last Updated:** 2024-01-15
