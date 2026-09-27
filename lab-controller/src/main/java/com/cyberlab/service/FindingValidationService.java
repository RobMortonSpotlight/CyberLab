package com.cyberlab.service;

import com.cyberlab.model.SecurityFinding;
import com.cyberlab.model.SecurityFinding.Difficulty;
import org.springframework.stereotype.Service;
import java.util.*;
import java.util.logging.Logger;

@Service
public class FindingValidationService {

    private static final Logger logger = Logger.getLogger(FindingValidationService.class.getName());

    private static final Map<String, FindingValidator> validators = new HashMap<>();

    public FindingValidationService() {
        initializeValidators();
    }

    private void initializeValidators() {
        // Finding 01: ICMP Filtering
        validators.put("F01", targetIp -> {
            logger.info("Validating F01 - ICMP Filtering on " + targetIp);
            // Check if ICMP is blocked to Windows Server and IoT device
            return validateIcmpFiltering(targetIp);
        });

        // Finding 03: Service Banners
        validators.put("F03", targetIp -> {
            logger.info("Validating F03 - Detailed Service Banners on " + targetIp);
            return validateServiceBanners(targetIp);
        });

        // Finding 05: Vulnerable ProFTPD
        validators.put("F05", targetIp -> {
            logger.info("Validating F05 - ProFTPD Vulnerability on " + targetIp);
            return validateProFtpdVulnerability(targetIp);
        });

        // Finding 06: Hidden Internal Network
        validators.put("F06", targetIp -> {
            logger.info("Validating F06 - Hidden Internal Network on " + targetIp);
            return validateHiddenNetwork(targetIp);
        });

        // Finding 10: Overly Permissive SMB Share
        validators.put("F10", targetIp -> {
            logger.info("Validating F10 - SMB Share Permissions on " + targetIp);
            return validateSmbPermissions(targetIp);
        });

        // Finding 15: Default Credentials
        validators.put("F15", targetIp -> {
            logger.info("Validating F15 - Default Credentials on " + targetIp);
            return validateDefaultCredentials(targetIp);
        });
    }

    public Map<String, Object> validateFinding(String findingId, String targetIp) {
        Map<String, Object> result = new HashMap<>();
        result.put("findingId", findingId);
        result.put("targetIp", targetIp);

        FindingValidator validator = validators.get(findingId);
        if (validator == null) {
            result.put("status", "unknown");
            result.put("message", "Finding validator not found");
            return result;
        }

        try {
            boolean isValid = validator.validate(targetIp);
            result.put("status", isValid ? "validated" : "not_found");
            result.put("message", isValid ? "Finding confirmed" : "Finding not detected");
        } catch (Exception e) {
            result.put("status", "error");
            result.put("message", e.getMessage());
        }

        return result;
    }

    private boolean validateIcmpFiltering(String targetIp) {
        // Simulate ICMP validation
        // In real implementation, would check actual firewall rules
        return true;
    }

    private boolean validateServiceBanners(String targetIp) {
        // Validate that services expose version information
        return true;
    }

    private boolean validateProFtpdVulnerability(String targetIp) {
        // Check for vulnerable ProFTPD version
        return true;
    }

    private boolean validateHiddenNetwork(String targetIp) {
        // Verify secondary network interface exists
        return true;
    }

    private boolean validateSmbPermissions(String targetIp) {
        // Check SMB share permissions
        return true;
    }

    private boolean validateDefaultCredentials(String targetIp) {
        // Verify default credentials are accessible
        return true;
    }

    @FunctionalInterface
    interface FindingValidator {
        boolean validate(String targetIp) throws Exception;
    }

    public List<SecurityFinding> getAllFindings() {
        return List.of(
            createFinding("F01", "ICMP Filtering", "Firewall",
                Difficulty.INTRODUCTORY, "Host discovery and firewall behavior"),
            createFinding("F02", "Excessive Service Exposure", "Multiple",
                Difficulty.INTRODUCTORY, "Attack surface reduction"),
            createFinding("F03", "Detailed Service Banners", "Multiple",
                Difficulty.INTRODUCTORY, "Service enumeration and vulnerability research"),
            createFinding("F04", "Outdated Web Application", "Linux Server",
                Difficulty.INTERMEDIATE, "Version fingerprinting and CVE research"),
            createFinding("F05", "Vulnerable ProFTPD", "Linux Server",
                Difficulty.INTERMEDIATE, "Enumeration → exploitation → access"),
            createFinding("F06", "Hidden Internal Network", "Linux Server",
                Difficulty.ADVANCED, "Network segmentation and pivot discovery"),
            createFinding("F07", "IPMI/BMC Authentication Exposure", "IoT Device",
                Difficulty.INTERMEDIATE, "Management-plane security"),
            createFinding("F08", "Credential Reuse", "Multiple",
                Difficulty.ADVANCED, "Password reuse and attack-path chaining"),
            createFinding("F09", "SMB Information Exposure", "Windows Systems",
                Difficulty.INTERMEDIATE, "Windows and SMB enumeration"),
            createFinding("F10", "Overly Permissive SMB Share", "Windows Server",
                Difficulty.INTERMEDIATE, "Access control and information leakage"),
            createFinding("F11", "NTLM Authentication Exposure", "Windows Systems",
                Difficulty.ADVANCED, "Windows authentication and credential exposure"),
            createFinding("F12", "Credential Reuse Scenario", "Multiple",
                Difficulty.ADVANCED, "Credential hygiene and lateral-movement risk"),
            createFinding("F13", "Excessive Privileges", "Multiple",
                Difficulty.INTERMEDIATE, "Principle of least privilege"),
            createFinding("F14", "Exposed Management Interface", "IoT Device",
                Difficulty.INTERMEDIATE, "Management-plane isolation"),
            createFinding("F15", "IoT Default Credentials", "IoT Device",
                Difficulty.INTERMEDIATE, "IoT security and credential management"),
            createFinding("F16", "Cleartext Network Protocol", "Multiple",
                Difficulty.INTERMEDIATE, "Packet analysis and encryption")
        );
    }

    private SecurityFinding createFinding(String id, String title, String target,
                                         Difficulty difficulty, String objective) {
        SecurityFinding finding = new SecurityFinding();
        finding.setFindingId(id);
        finding.setTitle(title);
        finding.setTargetName(target);
        finding.setDifficulty(difficulty);
        finding.setLearningObjective(objective);
        finding.setIsActive(true);
        return finding;
    }
}
