#!/bin/bash

export SUFFIX="demolb"
export RESOURCE_GROUP="rsg${SUFFIX}"
export LOCATION="westus"
# Network
export VNET_NAME="vnet${SUFFIX}"
export SUBNET_NAME="snt${SUFFIX}"
export PUBLIC_IP_LB="pip${SUFFIX}"
# LB
export LB_NAME="lb${SUFFIX}"
export BACKEND_POOL="bep${SUFFIX}"
export HEALTH_PROBE="hpb${SUFFIX}"
export RULE_NAME="rl${SUFFIX}"
# VM
export VM_SIZE="Standard_DS1_v2"
export USERNAME="azureuser"
export IMAGE="Ubuntu2404"
export NSG="nsg${SUFFIX}"

# Create Resource Group
echo "Creating Resource Group..."
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION

#-------------------------------------------------------------------------------------------------#
# Network

### Create VNet and Subnet
echo "Creating VNet and Subnet..."
az network vnet create \
    --name $VNET_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --subnet-name $SUBNET_NAME

### Create Public IP for Load Balancer
echo "Creating public IP for Load Balancer..."
az network public-ip create \
    --resource-group $RESOURCE_GROUP \
    --name $PUBLIC_IP_LB \
    --allocation-method Static \
    --sku Standard

sleep 10
#-------------------------------------------------------------------------------------------------#
# Load Balancer

### Create Load Balancer
echo "Creating Load Balancer..."
az network lb create \
    --resource-group $RESOURCE_GROUP \
    --name $LB_NAME \
    --sku Standard \
    --public-ip-address $PUBLIC_IP_LB \
    --frontend-ip-name "meuFrontend" \
    --backend-pool-name $BACKEND_POOL

### Create Health Probe
echo "Creating healthcheck probe..."
az network lb probe create \
    --resource-group $RESOURCE_GROUP \
    --lb-name $LB_NAME \
    --name $HEALTH_PROBE \
    --protocol Tcp \
    --port 80

### Create Load Balancer Rule
echo "Creating loadbalancer rule..."
az network lb rule create \
    --resource-group $RESOURCE_GROUP \
    --lb-name $LB_NAME \
    --name $RULE_NAME \
    --protocol Tcp \
    --frontend-port 80 \
    --backend-port 80 \
    --frontend-ip-name "meuFrontend" \
    --backend-pool-name $BACKEND_POOL \
    --probe-name $HEALTH_PROBE \
    --enable-tcp-reset true

#-------------------------------------------------------------------------------------------------#
# VM

### Create Network Security Group
echo "Creating a Network Security Group..."
az network nsg create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $NSG

az network nsg rule create \
    --resource-group $RESOURCE_GROUP \
    --nsg-name $NSG \
    --name "AllowHTTP" \
    --protocol Tcp \
    --direction Inbound \
    --priority 100 \
    --source-address-prefix "*" \
    --source-port-range "*" \
    --destination-address-prefix "*" \

### Create VMs (2)
for i in 1 2; do
    VM_NAME="vml${SUFFIX}$i"
    NIC_NAME="nic${SUFFIX}$i"

    ### Create NIC attached to Load Balancer
    echo "Creating NIC for $VM_NAME..."
    az network nic create \
        --resource-group $RESOURCE_GROUP \
        --name $NIC_NAME \
        --vnet-name $VNET_NAME \
        --subnet $SUBNET_NAME \
        --lb-name $LB_NAME \
        --lb-address-pools $BACKEND_POOL \
        --network-security-group $NSG

    ### Create VM
    echo "Creating VM $VM_NAME..."
    az vm create \
        --resource-group $RESOURCE_GROUP \
        --name $VM_NAME \
        --image $IMAGE \
        --size $VM_SIZE \
        --admin-username $USERNAME \
        --nics $NIC_NAME \
        --public-ip-sku Standard \
        --custom-data cloud-init.txt \
        --generate-ssh-keys
done

#-------------------------------------------------------------------------------------------------#
# Load Balancer setup done
echo "Setup done! The public IP of the Load Balancer is:"
az network public-ip show \
    --resource-group $RESOURCE_GROUP \
    --name $PUBLIC_IP_LB \
    --query "ipAddress" \
    --output tsv
