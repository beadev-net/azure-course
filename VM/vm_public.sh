#!/bin/bash

# Variables
export RESOURCE_GROUP_NAME="rg1demo"
export LOCATION="eastus"
# NETWORK
export VNET="vnt1demo"
export SUBNET="sbt1demo"
export PUBLIC_IP="pib1demo"
# VM
export NIC="nic1demopub"
export NSG="nsg1demopub"
export VM_NAME="lvm1demopub"
export IMAGE="Ubuntu2404"
export ADMIN_USER="azureuser"
export SKU_SIZE="Standard_D2a_v4"
export SHUTDOWN_TIME="23:59"

# Create a Resource Group
echo "Creating a Resource Group..."
az group create --name $RESOURCE_GROUP_NAME --LOCATION $LOCATION

# Create a Virtual Network with a Subnet
echo "Creating a Virtual Network with a Subnet..."
az network vnet create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $VNET \
  --address-prefix 10.1.0.0/16 \
  --subnet-name $SUBNET \
  --subnet-prefix 10.1.0.0/24

# Create a Public IP Address
echo "Creating a Public IP Address..."
az network public-ip create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $PUBLIC_IP \
  --alLOCATION-method Static

# Create a Network Security Group (optional but recommended)
echo "Creating a Network Security Group..."
az network nsg create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $NSG

# Create a Network Interface and attach it to the VNet/Subnet, NSG, and Public IP
echo "Creating a Network Interface..."
az network nic create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $NIC \
  --vnet-name $VNET \
  --subnet $SUBNET \
  --network-security-group $NSG \
  --public-ip-address $PUBLIC_IP

# Create the VM using the pre-created NIC
# The OS disk is automatically created (if not specified, Azure creates a default OS disk)
echo "Creating a Virtual Machine..."
az vm create \
  --resource-group $RESOURCE_GROUP_NAME \
  --location $LOCATION \
  --name $VM_NAME \
  --nics $NIC \
  --image $IMAGE \
  --admin-username $ADMIN_USER \
  --generate-ssh-keys \
  --size $SKU_SIZE \
  --custom-data ./VM/cloud-init.txt

az vm auto-shutdown -g $RESOURCE_GROUP_NAME -n $VM_NAME --time $SHUTDOWN_TIME