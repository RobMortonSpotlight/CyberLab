package com.cyberlab.service;

import com.cyberlab.model.LabTarget;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.RestClientException;
import java.time.LocalDateTime;
import java.util.*;
import java.net.Socket;
import java.util.logging.Logger;

@Service
public class LabHealthService {

    private static final Logger logger = Logger.getLogger(LabHealthService.class.getName());
    private final RestTemplate restTemplate = new RestTemplate();

    public Map<String, Object> checkTargetHealth(LabTarget target) {
        Map<String, Object> healthStatus = new HashMap<>();
        healthStatus.put("targetName", target.getName());
        healthStatus.put("ip", target.getIpAddress());
        healthStatus.put("timestamp", LocalDateTime.now());

        // Check TCP connectivity
        boolean tcpReachable = checkTcpConnectivity(target.getIpAddress(), target.getPort());
        healthStatus.put("tcpReachable", tcpReachable);

        // Check HTTP health endpoint if available
        if (target.getHealthCheckUrl() != null) {
            boolean httpHealthy = checkHttpHealth(target.getHealthCheckUrl());
            healthStatus.put("httpHealthy", httpHealthy);
        }

        // Overall status
        boolean isHealthy = tcpReachable;
        healthStatus.put("status", isHealthy ? "healthy" : "unhealthy");

        // Update target
        target.setStatus(isHealthy ? "running" : "unreachable");
        target.setLastChecked(LocalDateTime.now());

        logger.info("Health check for " + target.getName() + ": " + (isHealthy ? "OK" : "FAILED"));

        return healthStatus;
    }

    private boolean checkTcpConnectivity(String host, int port) {
        try (Socket socket = new Socket(host, port)) {
            socket.close();
            return true;
        } catch (Exception e) {
            logger.fine("TCP connection failed to " + host + ":" + port + ": " + e.getMessage());
            return false;
        }
    }

    private boolean checkHttpHealth(String healthUrl) {
        try {
            var response = restTemplate.getForObject(healthUrl, String.class);
            return response != null;
        } catch (RestClientException e) {
            logger.fine("HTTP health check failed for " + healthUrl + ": " + e.getMessage());
            return false;
        }
    }

    public Map<String, Object> checkLabOverallHealth(List<LabTarget> targets) {
        Map<String, Object> labHealth = new HashMap<>();
        labHealth.put("timestamp", LocalDateTime.now());
        labHealth.put("totalTargets", targets.size());

        int healthyCount = 0;
        List<Map<String, Object>> targetStatuses = new ArrayList<>();

        for (LabTarget target : targets) {
            Map<String, Object> status = checkTargetHealth(target);
            targetStatuses.add(status);
            if ("healthy".equals(status.get("status"))) {
                healthyCount++;
            }
        }

        labHealth.put("healthyTargets", healthyCount);
        labHealth.put("targetStatuses", targetStatuses);
        labHealth.put("overallStatus", healthyCount == targets.size() ? "all_healthy" : "degraded");

        return labHealth;
    }
}
