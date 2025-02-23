export RESOURCE_GROUP="rgbeadev"
export LOCATION="eastus"

# PUBLIC IP
export PUBLIC_IP_NAME="pibbeadev"
# VNET
export VNET_NAME="vnthub"
export SUBNET_NAME="GatewaySubnet"
export VPN_GATEWAY_NAME="vpnbeadev"
export ADDRESS_SPACE="10.0.0.0/16"
export GATEWAY_SUBNET="10.0.1.0/24"
# VPN
export VPN_SKU="VpnGw1"
export P2S_CLIENT_ADDRESS_POOL="10.20.0.0/24"
export VPN_PROTOCOL="OpenVPN"
export TENANT="9d02f340-b361-44ce-a7bb-5f7ba0a41266"
export AUDIENCE="c632b3df-fb67-4d84-bdcf-b95ad541b5c8"

# Criar um grupo de recursos
az group create --name $RESOURCE_GROUP --location $LOCATION

# Criar uma VNet com um Gateway Subnet
az network vnet create \
    --name $VNET_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --address-prefixes $ADDRESS_SPACE \
    --subnet-name $SUBNET_NAME \
    --subnet-prefix $GATEWAY_SUBNET

# Criar um IP público para o VPN Gateway
az network public-ip create \
    --name $PUBLIC_IP_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --allocation-method Static

# Criar o VPN Gateway
az network vnet-gateway create \
    --name $VPN_GATEWAY_NAME \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --vnet $VNET_NAME \
    --public-ip-address $PUBLIC_IP_NAME \
    --gateway-type Vpn \
    --vpn-type RouteBased \
    --sku $VPN_SKU \
    --asn 65515

# P2S VPN
az network vnet-gateway update \
    -n $VPN_GATEWAY_NAME \
    --resource-group $RESOURCE_GROUP \
    --aad-tenant "https://login.microsoftonline.com/$TENANT/" \
    --aad-audience "$AUDIENCE" \
    --aad-issuer "https://sts.windows.net/$TENANT/" \
    --address-prefixes $P2S_CLIENT_ADDRESS_POOL \
    --client-protocol $VPN_PROTOCOL

# Criar um certificado autoassinado
az network vnet-gateway vpn-client generate \
    --name $VPN_GATEWAY_NAME \
    --resource-group $RESOURCE_GROUP \
    --authentication-method EapTls