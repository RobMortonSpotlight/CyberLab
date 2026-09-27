package com.cyberlab.controller;

import com.cyberlab.model.LabTarget;
import com.cyberlab.model.SecurityFinding;
import com.cyberlab.service.LabHealthService;
import com.cyberlab.service.FindingValidationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.*;
import java.util.logging.Logger;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class LabController {

    private static final Logger logger = Logger.getLogger(LabController.class.getName());

    private final LabHealthService healthService;
    private final FindingValidationService findingValidationService;

    @Autowired
    public LabController(LabHealthService healthService, FindingValidationService findingValidationService) {
        this.healthService = healthService;
        this.findingValidationService = findingValidationService;
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> response = new HashMap<>();
        response.put("status", "healthy");
        response.put("service", "CyberLab Controller");
        response.put("version", "1.0.0");
        return ResponseEntity.ok(response);
    }

    @GetMapping("/lab/status")
    public ResponseEntity<Map<String, Object>> labStatus() {
        logger.info("Lab status check requested");
        List<LabTarget> targets = getDefaultTargets();
        Map<String, Object> labHealth = healthService.checkLabOverallHealth(targets);
        return ResponseEntity.ok(labHealth);
    }

    @GetMapping("/targets")
    public ResponseEntity<List<LabTarget>> listTargets() {
        logger.info("Listing all lab targets");
        return ResponseEntity.ok(getDefaultTargets());
    }

    @GetMapping("/targets/{name}")
    public ResponseEntity<Map<String, Object>> getTarget(@PathVariable String name) {
        logger.info("Getting target information: " + name);
        Map<String, Object> response = new HashMap<>();

        LabTarget target = getTargetByName(name);
        if (target == null) {
            response.put("error", "Target not found");
            return ResponseEntity.notFound().build();
        }

        response.put("target", target);
        response.put("health", healthService.checkTargetHealth(target));
        response.put("services", target.getServices());
        response.put("findings", target.getFindings());
        response.put("isInternal", target.getIsInternal());
        response.put("blocksIcmp", target.getBlocksIcmp());

        return ResponseEntity.ok(response);
    }

    @GetMapping("/findings")
    public ResponseEntity<List<SecurityFinding>> listFindings() {
        logger.info("Listing all security findings");
        return ResponseEntity.ok(findingValidationService.getAllFindings());
    }

    @GetMapping("/findings/by-target/{targetName}")
    public ResponseEntity<List<String>> findingsByTarget(@PathVariable String targetName) {
        logger.info("Getting findings for target: " + targetName);
        LabTarget target = getTargetByName(targetName);
        if (target == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(target.getFindings());
    }

    @PostMapping("/findings/validate/{findingId}")
    public ResponseEntity<Map<String, Object>> validateFinding(
            @PathVariable String findingId,
            @RequestParam String targetIp) {
        logger.info("Validating finding " + findingId + " on target " + targetIp);
        Map<String, Object> result = findingValidationService.validateFinding(findingId, targetIp);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/lab/topology")
    public ResponseEntity<Map<String, Object>> getNetworkTopology() {
        logger.info("Getting network topology");
        Map<String, Object> topology = new HashMap<>();

        topology.put("externalNetwork", Map.of(
            "subnet", "10.0.1.0/24",
            "gateway", "10.0.1.1",
            "description", "Student access network"
        ));

        topology.put("internalNetwork", Map.of(
            "subnet", "192.168.1.0/24",
            "gateway", "192.168.1.1",
            "description", "Protected internal network",
            "accessibleAfterPivot", true
        ));

        topology.put("firewall", Map.of(
            "role", "Gateway and segmentation",
            "blocksIcmp", List.of("192.168.1.30", "192.168.1.50"),
            "allowsTcp", true
        ));

        topology.put("learningObjectives", List.of(
            "ICMP filtering requires alternative discovery (nmap -Pn)",
            "Hidden internal network accessible after pivot point",
            "Credential reuse demonstrates attack chaining",
            "Management devices expose default credentials"
        ));

        return ResponseEntity.ok(topology);
    }

    @GetMapping("/lab/learning-paths")
    public ResponseEntity<Map<String, Object>> getLearningPaths() {
        logger.info("Getting learning paths");
        Map<String, Object> paths = new HashMap<>();

        paths.put("primaryPath", List.of(
            "Initial network access",
            "ICMP discovery fails → Recognize filtering",
            "Use nmap -Pn to discover Linux server",
            "Enumerate services on Linux",
            "Discover ProFTPD vulnerability",
            "Exploit for foothold",
            "Post-exploitation finds second interface",
            "Pivot to internal network",
            "Discover Windows and IoT systems",
            "Chain credentials to lateral movement"
        ));

        paths.put("alternativePaths", List.of(
            "DNS enumeration reveals internal hosts",
            "Banner grabbing discloses versions",
            "SMB enumeration via port scanning",
            "Default credentials on management devices"
        ));

        paths.put("findings", findingValidationService.getAllFindings());

        return ResponseEntity.ok(paths);
    }

    @GetMapping("/lab/nmap-guide")
    public ResponseEntity<Map<String, String>> getNmapGuide() {
        logger.info("Providing Nmap learning guide");
        Map<String, String> guide = new HashMap<>();

        guide.put("step1", "nmap -sn 10.0.1.0/24 → Initial discovery (ICMP-based)");
        guide.put("step2", "nmap -p- 10.0.1.10 → Comprehensive port scan on discovered host");
        guide.put("step3", "nmap -sV 10.0.1.10 → Service version detection");
        guide.put("step4", "nmap -Pn 192.168.1.0/24 → Scan without ICMP (when firewall blocks)");
        guide.put("step5", "nmap -O 10.0.1.10 → OS fingerprinting");
        guide.put("step6", "nmap --script smb-os-discovery 192.168.1.30 → SMB enumeration");

        guide.put("learning", "Understand why each scan succeeds or fails based on network position");

        return ResponseEntity.ok(guide);
    }

    @GetMapping("/lab/tcpdump-guide")
    public ResponseEntity<Map<String, String>> getTcpdumpGuide() {
        logger.info("Providing tcpdump learning guide");
        Map<String, String> guide = new HashMap<>();

        guide.put("capture_all", "tcpdump -i any -w traffic.pcap");
        guide.put("capture_smb", "tcpdump -i any -w smb.pcap port 445 or port 139");
        guide.put("capture_http", "tcpdump -i any -w http.pcap port 80 or port 443");
        guide.put("capture_dns", "tcpdump -i any -w dns.pcap port 53");
        guide.put("capture_ntlm", "tcpdump -i any -w ntlm.pcap port 445");
        guide.put("analyze", "Students use Wireshark to analyze captured traffic");

        return ResponseEntity.ok(guide);
    }

    private List<LabTarget> getDefaultTargets() {
        List<LabTarget> targets = new ArrayList<>();

        // Target 1: Firewall
        LabTarget firewall = new LabTarget();
        firewall.setName("firewall");
        firewall.setType("Firewall/Router");
        firewall.setIpAddress("192.168.1.1");
        firewall.setPort(53);
        firewall.setRole("Gateway and network segmentation");
        firewall.setServices(List.of("DNS", "IP Forwarding", "Packet Filtering"));
        firewall.setFindings(List.of("F01"));
        firewall.setIsInternal(true);
        firewall.setBlocksIcmp(false);
        targets.add(firewall);

        // Target 2: Linux Server
        LabTarget linuxServer = new LabTarget();
        linuxServer.setName("linux-server");
        linuxServer.setType("Linux Application Server");
        linuxServer.setIpAddress("10.0.1.10");
        linuxServer.setPort(22);
        linuxServer.setRole("Entry point with internal network access");
        linuxServer.setServices(List.of("SSH", "HTTP", "HTTPS", "FTP", "DNS"));
        linuxServer.setFindings(List.of("F02", "F03", "F05", "F06"));
        linuxServer.setIsInternal(false);
        linuxServer.setBlocksIcmp(false);
        linuxServer.setHealthCheckUrl("http://10.0.1.10/health");
        targets.add(linuxServer);

        // Target 3: Windows Workstation
        LabTarget wsWorkstation = new LabTarget();
        wsWorkstation.setName("windows-workstation");
        wsWorkstation.setType("Windows Workstation");
        wsWorkstation.setIpAddress("192.168.1.20");
        wsWorkstation.setPort(445);
        wsWorkstation.setRole("Employee workstation");
        wsWorkstation.setServices(List.of("SMB", "RPC", "NTLM"));
        wsWorkstation.setFindings(List.of("F09", "F10", "F11"));
        wsWorkstation.setIsInternal(true);
        wsWorkstation.setBlocksIcmp(false);
        targets.add(wsWorkstation);

        // Target 4: Windows Server
        LabTarget windowsServer = new LabTarget();
        windowsServer.setName("windows-server");
        windowsServer.setType("Windows Server");
        windowsServer.setIpAddress("192.168.1.30");
        windowsServer.setPort(445);
        windowsServer.setRole("File server and administrative infrastructure");
        windowsServer.setServices(List.of("SMB", "RPC", "PostgreSQL", "NTLM"));
        windowsServer.setFindings(List.of("F03", "F08", "F10", "F12", "F13", "F14"));
        windowsServer.setIsInternal(true);
        windowsServer.setBlocksIcmp(true);
        targets.add(windowsServer);

        // Target 5: IoT Device
        LabTarget iotDevice = new LabTarget();
        iotDevice.setName("iot-device");
        iotDevice.setType("IoT / Management Device");
        iotDevice.setIpAddress("192.168.1.50");
        iotDevice.setPort(8080);
        iotDevice.setRole("IPMI/BMC simulation");
        iotDevice.setServices(List.of("IPMI", "HTTP", "VNC"));
        iotDevice.setFindings(List.of("F07", "F14", "F15"));
        iotDevice.setIsInternal(true);
        iotDevice.setBlocksIcmp(true);
        iotDevice.setHealthCheckUrl("http://192.168.1.50:8080/health");
        targets.add(iotDevice);

        return targets;
    }

    private LabTarget getTargetByName(String name) {
        return getDefaultTargets().stream()
            .filter(t -> t.getName().equalsIgnoreCase(name))
            .findFirst()
            .orElse(null);
    }
}
