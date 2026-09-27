#!/bin/bash

# Deploy updated code to the CyberLab VM

VM_IP="20.51.184.16"
VM_USER="azureuser"

echo "=========================================="
echo "Deploying Updated CyberLab to VM"
echo "=========================================="
echo ""
echo "Target VM: $VM_IP"
echo ""

# Pull latest code from GitHub and restart services
ssh -o StrictHostKeyChecking=no $VM_USER@$VM_IP << 'EOF'

echo "Updating CyberLab from GitHub..."

# Navigate to the cyberlab directory
cd /home/cyberuser/cyberlab || cd /opt/cyberlab || cd ~/cyberlab

# Pull latest changes
git pull origin main

echo "✓ Code updated from GitHub"
echo ""

# Restart the student portal container
echo "Restarting student portal..."
docker-compose down cyberlab-student-portal-web 2>/dev/null || docker stop cyberlab-student-portal-web 2>/dev/null || true
sleep 2
docker-compose up -d cyberlab-student-portal-web 2>/dev/null || docker start cyberlab-student-portal-web 2>/dev/null || true

# Restart the terminal server
echo "Restarting terminal server..."
docker-compose down cyberlab-terminal-server 2>/dev/null || docker stop cyberlab-terminal-server 2>/dev/null || true
sleep 2
docker-compose up -d cyberlab-terminal-server 2>/dev/null || docker start cyberlab-terminal-server 2>/dev/null || true

echo "✓ Services restarted"
echo ""
echo "CyberLab updated successfully!"

EOF

echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Your updated CyberLab is now live"
echo "Access at: http://20.51.184.16:3001/main.html"
echo ""
