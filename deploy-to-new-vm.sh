#!/bin/bash
set -e

echo "=================================="
echo "CyberLab VM Deployment Script"
echo "=================================="
echo ""

# Update system
echo "Step 1: Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
echo "Step 2: Installing Docker..."
sudo apt-get install -y docker.io docker-compose
sudo usermod -aG docker $USER
echo "✓ Docker installed"

# Install Ollama
echo "Step 3: Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh
echo "✓ Ollama installed"

# Pull models in background
echo "Step 4: Starting model downloads (background)..."
ollama pull mistral &
ollama pull llama2 &
echo "✓ Models downloading in background..."

# Clone/pull CyberLab repo
echo "Step 5: Setting up CyberLab..."
if [ -d "cyberlab" ]; then
  cd cyberlab
  git pull origin main
else
  git clone https://github.com/gim-home/LANDON.git cyberlab
  cd cyberlab
fi

# Build Docker image
echo "Step 6: Building Docker image..."
docker build -t cyberlab:latest -f Dockerfile .
echo "✓ Docker image built"

# Start Ollama service
echo "Step 7: Starting Ollama service..."
sudo systemctl start ollama
sudo systemctl enable ollama
echo "✓ Ollama service started"

# Wait for models to finish downloading
echo "Step 8: Waiting for models to download (this may take 10-15 minutes)..."
wait
echo "✓ Models downloaded"

# Start CyberBeacon container
echo "Step 9: Starting CyberBeacon..."
docker run -d \
  --name cyberbeacon \
  -p 3000:3000 \
  -p 3001:3001 \
  -e OLLAMA_HOST="http://localhost:11434" \
  cyberlab:latest

echo ""
echo "=================================="
echo "✅ Deployment Complete!"
echo "=================================="
echo ""
echo "CyberBeacon is running at:"
echo "  http://$(hostname -I | awk '{print $1}'):3001/main.html"
echo ""
echo "Models available:"
echo "  - Mistral (fast, recommended)"
echo "  - Llama2 (slower but more capable)"
echo ""
echo "API Health Check:"
curl -s http://localhost:3001/api/terminal-health | jq '.' || echo "Still starting..."
