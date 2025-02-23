#!/bin/bash

# Variables
export SUFFIX="1demo"
export RESOURCE_GROUP_NAME="rg${SUFFIX}"
export LOCATION="eastus"
export LAW_NAME="law${SUFFIX}"
# NETWORK
export VNET="vnt${SUFFIX}"
export SUBNET="sbt${SUFFIX}"
export VNET_ADDRESS_PREFIX="10.1.0.0/16"
export SUBNET_ADDRESS_PREFIX="10.1.0.0/24"
# VM
export NSG="nsg${SUFFIX}priv"
export NIC="nic${SUFFIX}priv"
export VM_NAME="lvm${SUFFIX}priv"
export IMAGE="Ubuntu2404"
export ADMIN_USER="azureuser"
export SKU_SIZE="Standard_D2a_v4"
export SHUTDOWN_TIME="23:59"

# Create a Resource Group
echo "Creating a Resource Group..."
az group create --name $RESOURCE_GROUP_NAME --location $LOCATION

# Create a Virtual Network with a Subnet
echo "Creating a Virtual Network with a Subnet..."
az network vnet create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $VNET \
  --address-prefix $VNET_ADDRESS_PREFIX \
  --subnet-name $SUBNET \
  --subnet-prefix $SUBNET_ADDRESS_PREFIX

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
  --network-security-group $NSG

# Create the VM using the pre-created NIC
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
  --custom-data cloud-init.txt

# Enable Auto-Shutdown
echo "VM created successfully!"
az vm auto-shutdown -g $RESOURCE_GROUP_NAME -n $VM_NAME --time $SHUTDOWN_TIME

echo "Sleeping for 30 seconds... Waiting for the VM to be ready..."
sleep 30

export VM_ID=$(az vm show -g $RESOURCE_GROUP_NAME -n $VM_NAME --query id)

# Enable the Azure Monitor VM Extension
echo "Enabling the Azure Monitor VM Extension..."
az vm extension set \
    --name AzureMonitorLinuxAgent \
    --publisher Microsoft.Azure.Monitor \
    --ids $VM_ID \
    --enable-auto-upgrade true

# Create in DCE (Data Collection Endpoint)
echo "Creating a Data Collection Endpoint..."
az monitor data-collection endpoint create \
    -g $RESOURCE_GROUP_NAME \
    -l $LOCATION \
    --name "dce${SUFFIX}" \
    --public-network-access "SecuredByPerimeter"

# Create Log Analytics
echo "Creating a Log Analytics Workspace..."
az monitor log-analytics workspace create \
    --resource-group $RESOURCE_GROUP_NAME \
    --workspace-name $LAW_NAME \
    --location $LOCATION


export DCE_ID=$(az monitor data-collection endpoint show -g $RESOURCE_GROUP_NAME -n "dce${SUFFIX}" --query id)
export LAW_ID=$(az monitor log-analytics workspace show -g $RESOURCE_GROUP_NAME -n $LAW_NAME --query id)

# Create DCR (Data Collection Rule)
echo "Creating a Data Collection Rule..."
az monitor data-collection rule create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --name "dcr${SUFFIX}" \
    --kind "Linux" \
    --data-collection-endpoint-id "/subscriptions/677253fa-9e72-4166-ac53-247de4fb2181/resourceGroups/rg1demo/providers/Microsoft.Insights/dataCollectionEndpoints/dce1demo" \
    --data-sources '{
            "syslog": [
                {
                    "name": "sysLogsDataSource-9999999",
                    "streams": [
                        "Microsoft-Syslog"
                    ],
                    "facilityNames": [
                        "alert",
                        "audit",
                        "auth",
                        "authpriv",
                        "clock",
                        "cron",
                        "daemon",
                        "ftp",
                        "kern",
                        "local0",
                        "local1",
                        "local2",
                        "local3",
                        "local4",
                        "local5",
                        "local6",
                        "local7",
                        "lpr",
                        "mail",
                        "news",
                        "nopri",
                        "ntp",
                        "syslog",
                        "user",
                        "uucp"
                    ],
                    "logLevels": [
                        "Debug",
                        "Info",
                        "Notice",
                        "Warning",
                        "Error",
                        "Critical",
                        "Alert",
                        "Emergency"
                    ],
                }
            ]
        }' \
    --destinations '{
            "logAnalytics": [
                {
                    "workspaceResourceId": '"${LAW_ID}"',
                    "name": "la--9999999"
                }
            ]
        }' \
    --data-flows '[
            {
                "streams": [
                    "Microsoft-Syslog"
                ],
                "destinations": [
                    "la--9999999"
                ],
                "transformKql": "source",
                "outputStream": "Microsoft-Syslog"
            }
        ]'

export DCR_ID=$(az monitor data-collection rule show -g $RESOURCE_GROUP_NAME -n "dcr${SUFFIX}" --query id)

# Create DCRA (Data Collection Rule Association)
echo "Creating a Data Collection Rule Association..."
az monitor data-collection rule association create \
    --name "dcra${SUFFIX}" \
    --rule-id $DCR_ID \
    --resource $VM_ID