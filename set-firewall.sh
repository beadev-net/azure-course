export RG=test-firewall-rg
export LOCATION=eastus
export VM_NAME=vm1
export VNET_NAME=workload-vn
export SUBNET_NAME=workload-subnet
export ROUTE_TABLE=firewall-rt-table
export FW=test-fw
export FW_M_PIP=fw-m-pip
export FW_PIP=fw-pip
export FW_POLICY=$FW-policy
export FW_IP_CONFIG=fw-config

# Resource Group
az group create --name $RG --location $LOCATION

# Network
az network vnet create --name $VNET_NAME --resource-group $RG --location $LOCATION --address-prefix 10.0.0.0/16 --subnet-name AzureFirewallSubnet --subnet-prefix 10.0.1.0/26
az network vnet subnet create --name $SUBNET_NAME --resource-group $RG --vnet-name $VNET_NAME --address-prefix 10.0.2.0/24
az network vnet subnet create -n AzureFirewallManagementSubnet -g $RG --vnet-name $VNET_NAME --address-prefixes 10.0.3.0/24

# VM
az vm create --resource-group $RG --name $VM_NAME --location $LOCATION --image Ubuntu2204 --generate-ssh-keys --subnet $SUBNET_NAME --vnet-name $VNET_NAME
az vm open-port --port 22 --resource-group $RG --name $VM_NAME

## Criar SSH Key e Baixar
## chmod 700 <key>
## Conectar na VM e rodar o script abaixo
### sudo apt update && apt install nginx -y


# NIC
export NIC_ID=$(az vm nic list -g $RG --vm-name $VM_NAME --query "[0].id" --output tsv)
az network nic update --resource-group $RG --id $NIC_ID --dns-servers 209.244.0.3 209.244.0.4 8.8.8.8

# Restart VM
az vm restart --resource-group $RG --name $VM_NAME

# Firewall
az network public-ip create --name $FW_PIP --resource-group $RG --location $LOCATION --allocation-method static --sku standard
az network public-ip create --name $FW_M_PIP --resource-group $RG --location $LOCATION --allocation-method static --sku standard
az network firewall policy create --name $FW_POLICY --resource-group $RG --location $LOCATION --sku Basic
export FW_POLICY_ID=$(az network firewall policy list --query "[0].id" --output tsv)
az network firewall create --name $FW --resource-group $RG --location $LOCATION --sku AZFW_VNet --tier basic --conf-name fw-ipconfig --m-conf-name fw-ipconfig-manage --m-public-ip $FW_M_PIP --public-ip $FW_PIP --vnet-name $VNET_NAME --firewall-policy $FW_POLICY_ID
az network public-ip show --name $FW_PIP --resource-group $RG --query "ipAddress" --output tsv
export FW_PRIV_ADDR="$(az network firewall ip-config list -g $RG -f $FW --query "[0].privateIpAddress" --output tsv)"

# Route Table
az network route-table create --name $ROUTE_TABLE --resource-group $RG --location $LOCATION --disable-bgp-route-propagation true
az network route-table route create --resource-group $RG --name all-to-firewall --route-table-name $ROUTE_TABLE --address-prefix 0.0.0.0/0 --next-hop-type VirtualAppliance --next-hop-ip-address $FW_PRIV_ADDR
az network vnet subnet update -n $SUBNET_NAME -g $RG --vnet-name $VNET_NAME --address-prefixes 10.0.2.0/24 --route-table $ROUTE_TABLE

# Firewall rules
## Google HTTP/HTTPS
export RCG=default-rule-collection-group
az network firewall policy rule-collection-group create --name $RCG --policy-name $FW_POLICY --priority 100 --resource-group $RG
az network firewall policy rule-collection-group collection add-filter-collection \
    --collection-priority 200 \
    --name allow-google \
    --rcg-name $RCG \
    --policy-name $FW_POLICY \
    --rule-type ApplicationRule \
    --protocols Http=80 Https=443 \
    --resource-group $RG \
    --target-fqdns www.google.com \
    --source-addresses 10.0.2.0/24 \
    --action Allow

## DNS
az network firewall policy rule-collection-group collection add-filter-collection \
    -g $RG \
    --policy-name $FW_POLICY \
    --rule-collection-group-name $RCG \
    --name allow-dns \
    --action Allow \
    --rule-name network_rule \
    --rule-type NetworkRule \
    --description "test" \
    --destination-addresses "209.244.0.3" "209.244.0.4" "8.8.8.8" \
    --source-addresses "10.0.2.0/24" \
    --destination-ports "*" \
    --ip-protocols TCP UDP \
    --collection-priority 400

## SSH
export FW_PIP_ADDRESS=$(az network public-ip show --name $FW_PIP -g $RG --query "ipAddress" --output tsv)
az network firewall policy rule-collection-group collection add-nat-collection \
    -g $RG \
    --policy-name $FW_POLICY \
    --rule-collection-group-name $RCG \
    --name allow-ssh \
    --action DNAT \
    --rule-name allow-ssh-22 \
    --dest-addr $FW_PIP_ADDRESS \
    --destination-ports 22 \
    --source-addresses "*" \
    --ip-protocols TCP \
    --translated-address "10.0.2.4" \
    --translated-port 22 \
    --collection-priority 180

## NGINX
az network firewall policy rule-collection-group collection add-nat-collection \
    -g $RG \
    --policy-name $FW_POLICY \
    --rule-collection-group-name $RCG \
    --name allow-nginx \
    --action DNAT \
    --rule-name allow-nginx \
    --dest-addr $FW_PIP_ADDRESS \
    --destination-ports 80 \
    --source-addresses "*" \
    --ip-protocols TCP \
    --translated-address "10.0.2.4" \
    --translated-port 80 \
    --collection-priority 180    
