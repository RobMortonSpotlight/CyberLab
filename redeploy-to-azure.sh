#!/bin/bash

# Quick redeploy script for updated services (without Docker daemon)

set -e

SUBSCRIPTION_ID="a0e44210-16ec-4c0f-a02d-790369f3e971"
RESOURCE_GROUP="cyberpathways-rg"
REGISTRY_NAME="cyberlabregistry"

echo "=========================================="
echo "CyberLab Azure Quick Redeploy"
echo "=========================================="
echo ""

# Set subscription context
echo "Setting subscription context..."
az account set --subscription "$SUBSCRIPTION_ID"
echo "✓ Subscription set"
echo ""

# Get registry URL
REGISTRY_URL=$(az acr show --resource-group "$RESOURCE_GROUP" --name "$REGISTRY_NAME" --query loginServer -o tsv)
echo "Registry URL: $REGISTRY_URL"
echo ""

# Build image directly using Azure (no Docker daemon needed)
echo "Building and pushing updated terminal-server image to Azure..."
cd /Users/robertmorton/cyberlab
az acr build --registry "$REGISTRY_NAME" \
    --image "cyberlab/terminal-server:latest" \
    --file "student-portal/Dockerfile" \
    "student-portal"
echo "✓ Terminal server image built and pushed"
echo ""

# Get App Service details
APP_SERVICE_NAME="cyberlab-portal"
echo "Updating App Service with new image..."

# Get credentials
CREDENTIALS=$(az acr credential show --resource-group "$RESOURCE_GROUP" --name "$REGISTRY_NAME")
USERNAME=$(echo $CREDENTIALS | jq -r '.username')
PASSWORD=$(echo $CREDENTIALS | jq -r '.passwords[0].value')

# Update the app service
az webapp config container set \
    --resource-group "$RESOURCE_GROUP" \
    --name "$APP_SERVICE_NAME" \
    --docker-custom-image-name "$REGISTRY_URL/cyberlab/terminal-server:latest" \
    --docker-registry-server-url "https://$REGISTRY_URL" \
    --docker-registry-server-user "$USERNAME" \
    --docker-registry-server-password "$PASSWORD"

echo "✓ App Service configuration updated"
echo ""

# Restart the app service to pull new image
echo "Restarting App Service..."
az webapp restart --resource-group "$RESOURCE_GROUP" --name "$APP_SERVICE_NAME"
echo "✓ App Service restarted"
echo ""

echo "=========================================="
echo "Redeploy Complete!"
echo "=========================================="
echo ""
echo "Your updated CyberLab is being deployed..."
echo "Should be live in 2-3 minutes"
echo "Access at: http://20.51.184.16:3001/main.html"
echo ""
