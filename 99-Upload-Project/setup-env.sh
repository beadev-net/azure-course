#!/bin/bash

export SUFFIX="demoupload"
export RESOURCE_GROUP="rsg${SUFFIX}"
export LOCATION="eastus"
export ACR_NAME="acr${SUFFIX}"
export WEBAPP_NAME="wap${SUFFIX}"
export PLAN_NAME="svp${SUFFIX}"
export STORAGE_ACCOUNT="sta${SUFFIX}"
export CONTAINER_NAME="uploads"

# Creating Resource Group
echo "Creating Resource Group..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

# Creating Azure Container Registry
echo "Creating Azure Container Registry..."
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Basic \
    --admin-enabled true

#--------------------------------------------------------------------------------------------------#
# Storage Account

### Creating Storage Account
echo "Criando Storage Account..."
az storage account create \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS

### Creating Blob Storage Container
echo "Criando container no Blob Storage..."
az storage container create \
    --name $CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT

#--------------------------------------------------------------------------------------------------#
# Web App

### Creating App Service Plan
echo "Creating App Service Plan..."
az appservice plan create \
    --name $PLAN_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --is-linux \
    --sku B1

### Creating Web App
echo "Creating Web App..."
az webapp create \
    --resource-group $RESOURCE_GROUP \
    --plan $PLAN_NAME \
    --name $WEBAPP_NAME \
    --deployment-container-image-name nginx

### Configuring Web App to use ACR
echo "Configurando Web App para usar o ACR..."
az webapp config container set \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP \
    --docker-custom-image-name "$ACR_NAME.azurecr.io/appdemoupload:latest" \
    --docker-registry-server-url "https://$ACR_NAME.azurecr.io"

#--------------------------------------------------------------------------------------------------#
# Managed Identity

### Configuring Managed Identity
echo "Creating Web App identity..."
az webapp identity assign \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP

### Granting permission for Web App to pull images from ACR
echo "Granting permission for Web App to pull images from ACR..."
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "id" --output tsv)
WEBAPP_ID=$(az webapp show --name $WEBAPP_NAME --resource-group $RESOURCE_GROUP --query "identity.principalId" --output tsv)
az role assignment create \
    --assignee $WEBAPP_ID \
    --scope $ACR_ID \
    --role "AcrPull"

### Granting permission for Web App to write to Blob Storage
STORAGE_ACCOUNT_ID=$(az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query "id" --output tsv)
az role assignment create \
    --assignee $WEBAPP_ID \
    --scope $STORAGE_ACCOUNT_ID 
    --role "Storage Blob Data Contributor"

#--------------------------------------------------------------------------------------------------#
# Output
echo "Setup completed!"
echo "https://$WEBAPP_NAME.azurewebsites.net"
