#!/bin/bash

# CyberLab Azure Deployment Script
# This script deploys the CyberLab project to Azure using Azure CLI

set -e

# Configuration
SUBSCRIPTION_ID="a0e44210-16ec-4c0f-a02d-790369f3e971"
RESOURCE_GROUP="cyberpathways-rg"
REGISTRY_NAME="cyberlabregistry"
REGION="eastus"
APP_SERVICE_PLAN="cyberpathways-plan"
APP_SERVICE_NAME="cyberlab-portal"

echo "=========================================="
echo "CyberLab Azure Deployment"
echo "=========================================="
echo "Subscription: CyberPathways"
echo "Resource Group: $RESOURCE_GROUP"
echo "Region: $REGION"
echo ""

# Step 1: Set subscription context
echo "Step 1: Setting subscription context..."
az account set --subscription "$SUBSCRIPTION_ID"
echo "✓ Subscription set to CyberPathways"
echo ""

# Step 2: Verify resource group exists
echo "Step 2: Verifying resource group..."
if az group exists --name "$RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID" | grep -q true; then
    echo "✓ Resource group '$RESOURCE_GROUP' found"
else
    echo "✗ Resource group not found. Creating..."
    az group create --name "$RESOURCE_GROUP" --location "$REGION"
    echo "✓ Resource group created"
fi
echo ""

# Step 3: Create Azure Container Registry (if it doesn't exist)
echo "Step 3: Checking Azure Container Registry..."
if az acr show --resource-group "$RESOURCE_GROUP" --name "$REGISTRY_NAME" &>/dev/null; then
    echo "✓ Container Registry '$REGISTRY_NAME' already exists"
else
    echo "Creating Container Registry..."
    az acr create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$REGISTRY_NAME" \
        --sku Basic \
        --admin-enabled true
    echo "✓ Container Registry created"
fi

REGISTRY_URL=$(az acr show --resource-group "$RESOURCE_GROUP" --name "$REGISTRY_NAME" --query loginServer -o tsv)
echo "Registry URL: $REGISTRY_URL"
echo ""

# Step 4: Login to Azure Container Registry
echo "Step 4: Logging in to Container Registry..."
az acr login --name "$REGISTRY_NAME"
echo "✓ Logged in to Container Registry"
echo ""

# Step 5: Build and push Docker images
echo "Step 5: Building and pushing Docker images..."
cd /Users/robertmorton/cyberlab

# Build lab targets
echo "Building lab target images..."
for target in firewall linux-server windows-workstation windows-server iot-device; do
    echo "  - Building $target..."
    az acr build --registry "$REGISTRY_NAME" \
        --image "cyberlab/$target:latest" \
        --file "targets/$target/Dockerfile" \
        "targets/$target"
done
echo "✓ Lab target images built and pushed"
echo ""

# Build lab controller
echo "Building lab controller..."
az acr build --registry "$REGISTRY_NAME" \
    --image "cyberlab/lab-controller:latest" \
    --file "lab-controller/Dockerfile" \
    "lab-controller"
echo "✓ Lab controller image built and pushed"
echo ""

# Build terminal server
echo "Building terminal server..."
az acr build --registry "$REGISTRY_NAME" \
    --image "cyberlab/terminal-server:latest" \
    --file "student-portal/Dockerfile" \
    "student-portal"
echo "✓ Terminal server image built and pushed"
echo ""

# Step 6: Create App Service Plan (for student portal)
echo "Step 6: Setting up App Service for Student Portal..."
if az appservice plan show --resource-group "$RESOURCE_GROUP" --name "$APP_SERVICE_PLAN" &>/dev/null; then
    echo "✓ App Service Plan '$APP_SERVICE_PLAN' already exists"
else
    echo "Creating App Service Plan..."
    az appservice plan create \
        --name "$APP_SERVICE_PLAN" \
        --resource-group "$RESOURCE_GROUP" \
        --sku B2 \
        --is-linux
    echo "✓ App Service Plan created"
fi
echo ""

# Step 7: Create or update App Service
echo "Step 7: Deploying Student Portal to App Service..."
if az webapp show --resource-group "$RESOURCE_GROUP" --name "$APP_SERVICE_NAME" &>/dev/null; then
    echo "Updating existing App Service..."
    az webapp update \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_SERVICE_NAME" \
        --docker-custom-image-name "$REGISTRY_URL/cyberlab/terminal-server:latest" \
        --docker-registry-server-url "https://$REGISTRY_URL" \
        --docker-registry-server-user $(az acr credential show --resource-group "$RESOURCE_GROUP" --name "$REGISTRY_NAME" --query username -o tsv) \
        --docker-registry-server-password $(az acr credential show --resource-group "$RESOURCE_GROUP" --name "$REGISTRY_NAME" --query "passwords[0].value" -o tsv)
else
    echo "Creating new App Service..."
    az webapp create \
        --resource-group "$RESOURCE_GROUP" \
        --plan "$APP_SERVICE_PLAN" \
        --name "$APP_SERVICE_NAME" \
        --deployment-container-image-name "$REGISTRY_URL/cyberlab/terminal-server:latest"

    echo "Configuring App Service..."
    az webapp config container set \
        --resource-group "$RESOURCE_GROUP" \
        --name "$APP_SERVICE_NAME" \
        --docker-custom-image-name "$REGISTRY_URL/cyberlab/terminal-server:latest" \
        --docker-registry-server-url "https://$REGISTRY_URL" \
        --docker-registry-server-user $(az acr credential show --resource-group "$RESOURCE_GROUP" --name "$REGISTRY_NAME" --query username -o tsv) \
        --docker-registry-server-password $(az acr credential show --resource-group "$RESOURCE_GROUP" --name "$REGISTRY_NAME" --query "passwords[0].value" -o tsv)
fi

APP_URL=$(az webapp show --resource-group "$RESOURCE_GROUP" --name "$APP_SERVICE_NAME" --query defaultHostName -o tsv)
echo "✓ App Service deployed"
echo "Portal URL: https://$APP_URL"
echo ""

# Step 8: Display deployment summary
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Resources Created/Updated:"
echo "  • Resource Group: $RESOURCE_GROUP"
echo "  • Container Registry: $REGISTRY_NAME ($REGISTRY_URL)"
echo "  • App Service Plan: $APP_SERVICE_PLAN"
echo "  • App Service: $APP_SERVICE_NAME"
echo ""
echo "Access your CyberLab Portal:"
echo "  https://$APP_URL"
echo ""
echo "Next Steps:"
echo "1. Deploy lab infrastructure with Docker Compose to a VM or ACI"
echo "2. Configure networking between App Service and lab infrastructure"
echo "3. Update app settings with lab backend URLs"
echo ""
echo "Azure CLI Commands Reference:"
echo "  az group show --name $RESOURCE_GROUP"
echo "  az acr show --resource-group $RESOURCE_GROUP --name $REGISTRY_NAME"
echo "  az webapp show --resource-group $RESOURCE_GROUP --name $APP_SERVICE_NAME"
echo ""
