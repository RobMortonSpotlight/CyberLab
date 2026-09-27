#!/bin/bash
set -e

echo "[LAB-CONTROLLER] CyberLab Controller starting..."
echo "[LAB-CONTROLLER] Java Options: $JAVA_OPTS"
echo "[LAB-CONTROLLER] Profile: $SPRING_PROFILES_ACTIVE"

# Wait for dependent services to be ready
echo "[LAB-CONTROLLER] Waiting for lab targets to be ready..."
sleep 5

# Start Spring Boot application
echo "[LAB-CONTROLLER] Starting Spring Boot application..."
exec java $JAVA_OPTS -jar /app/cyberlab-controller.jar
