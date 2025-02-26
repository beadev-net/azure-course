#!/bin/bash
# get current date as His using shell
export DATE=$(date +'%m%d%H%M%S')
export SUFFIX="demoupload${DATE}" 
export RESOURCE_GROUP="rsg${SUFFIX}"
export LOCATION="brazilsouth"
export ACR_NAME="acr${SUFFIX}"
export WEBAPP_NAME="wap${SUFFIX}"
export PLAN_NAME="svp${SUFFIX}"
export STORAGE_ACCOUNT="sta${SUFFIX}"
export CONTAINER_NAME="uploads"

# Creating Resource Group
echo "Creating Resource Group..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION || { echo "Failed to create resource group"; exit 1; }

# Creating Azure Container Registry
echo "Creating Azure Container Registry..."
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Basic \
    --admin-enabled true || { echo "Failed to create ACR"; exit 1; }

#--------------------------------------------------------------------------------------------------#
# Storage Account

### Creating Storage Account
echo "Creating Storage Account..."
az storage account create \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS || { echo "Failed to create storage account"; exit 1; }

### Creating Blob Storage Container
echo "Creating container in Blob Storage..."
az storage container create \
    --name $CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT || { echo "Failed to create blob container"; exit 1; }

#--------------------------------------------------------------------------------------------------#
# Web App

### Creating App Service Plan
echo "Creating App Service Plan..."
az appservice plan create \
    --name $PLAN_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --is-linux \
    --sku Free || { echo "Failed to create app service plan"; exit 1; }

### Creating Web App
echo "Creating Web App..."
az webapp create \
    --resource-group $RESOURCE_GROUP \
    --plan $PLAN_NAME \
    --name $WEBAPP_NAME \
    --deployment-container-image-name nginx || { echo "Failed to create web app"; exit 1; }

### Configuring Web App to use ACR
echo "Configuring Web App to use ACR..."
az webapp config container set \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP \
    --docker-custom-image-name "$ACR_NAME.azurecr.io/appdemoupload:latest" \
    --docker-registry-server-url "https://$ACR_NAME.azurecr.io" || { echo "Failed to configure web app to use ACR"; exit 1; }

#--------------------------------------------------------------------------------------------------#
# Managed Identity

### Configuring Managed Identity
echo "Creating Web App identity..."
az webapp identity assign \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP || { echo "Failed to assign identity to web app"; exit 1; }

### Granting permission for Web App to pull images from ACR
echo "Granting permission for Web App to pull images from ACR..."
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "id" --output tsv)
WEBAPP_ID=$(az webapp show --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP --query "identity.principalId" --output tsv)
az role assignment create \
    --assignee-object-id $WEBAPP_ID \
    --scope $ACR_ID \
    --role "AcrPull" || { echo "Failed to grant ACR pull permission"; exit 1; }

### Granting permission for Web App to write to Blob Storage
STORAGE_ACCOUNT_ID=$(az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query "id" --output tsv)
az role assignment create \
    --assignee-object-id $WEBAPP_ID \
    --scope $STORAGE_ACCOUNT_ID  \
    --role "Storage Blob Data Contributor" || { echo "Failed to grant blob storage write permission"; exit 1; }

#--------------------------------------------------------------------------------------------------#
# Output
echo "Setup completed!"
echo "https://$WEBAPP_NAME.azurewebsites.net"
