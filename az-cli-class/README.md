# AZ CLI

[Click Here to Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli#install)

---

## Global Arguments

```sh
Global Arguments
    --debug                  : Increase logging verbosity to show all debug logs.
    --help -h                : Show this help message and exit.
    --only-show-errors       : Only show errors, suppressing warnings.
    --output -o              : Output format. Allowed values: json, jsonc, none, table, tsv, yaml, yamlc. Default: json.
    --query                  : JMESPath query string. See http://jmespath.org/ for more information and examples.
    --verbose                : Increase logging verbosity. Use --debug for full debug logs.
```

---

## AZ Login

```sh
# Login interactively
az login

# Login with a service principal and secret
az login --service-principal -u <app-id> -p <password> -t <tenant-id>

# Login with a service principal and certificate
az login --service-principal -u <app-id> --certificate /path/to/cert.pem --tenant <tenant-id>

# Logout
az logout
```

---

## AZ Token

```sh
# Get Access Token
TOKEN=$(az account get-access-token --resource https://management.azure.com/ --query accessToken --output tsv)

# Get Subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

# Use the token with curl
curl -X GET https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourcegroups?api-version=2021-04-01 \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" | jq
```

---

## Account

```sh
# List all subscriptions
az account list --output table

# Set the active subscription
az account set --subscription "<subscription-id>"

# Show the current logged-in user
az ad signed-in-user show

# Show the role assignments for the current user
az role assignment list --all --output table
```

> [!NOTE]
> The AZ CLI enable only one subscription at a time and the subscription is linked with one user per time. If you want to login with another user then you need to `logout` and `login` again.

---

## Role-Based Access Control (RBAC)

```sh
az role definition list --name "<role-name>" --output json
```

```sh
az role definition create --role-definition '{ "Name": "Contoso On-call", "Description": "Perform VM actions and read storage and network information.", "Actions": [ "Microsoft.Compute/*/read", "Microsoft.Compute/virtualMachines/start/action", "Microsoft.Compute/virtualMachines/restart/action", "Microsoft.Network/*/read", "Microsoft.Storage/*/read", "Microsoft.Authorization/*/read", "Microsoft.Resources/subscriptions/resourceGroups/read", "Microsoft.Resources/subscriptions/resourceGroups/resources/read", "Microsoft.Insights/alertRules/*", "Microsoft.Support/*" ], "DataActions": [ "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/*" ], "NotDataActions": [ "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write" ], "AssignableScopes": ["/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"] }'

az role definition create --role-definition @ad-role.json
```

---

## Resource Groups

```sh
# Create a resource group
az group create --name <resource-group-name> --location <location>

# List resource groups
az group list --output table

# Delete a resource group
az group delete --name <resource-group-name> --yes --no-wait
```

---

## Storage Accounts

```sh
# List storage accounts
az storage account list --output table

# Create a storage account
az storage account create --name <storage-account-name> --resource-group <resource-group-name> --location <location> --sku Standard_LRS

# Get connection string for a storage account
az storage account show-connection-string --name <storage-account-name> --resource-group <resource-group-name> --output tsv
```

---

## Virtual Machines

```sh
# List VMs
az vm list --output table

# Create a VM
az vm create \
  --resource-group <resource-group-name> \
  --name <vm-name> \
  --image UbuntuLTS \
  --admin-username <admin-username> \
  --generate-ssh-keys

# Start a VM
az vm start --resource-group <resource-group-name> --name <vm-name>

# Stop a VM
az vm stop --resource-group <resource-group-name> --name <vm-name>

# Delete a VM
az vm delete --resource-group <resource-group-name> --name <vm-name> --yes
```

---

## Networking

```sh
# List virtual networks
az network vnet list --output table

# Create a virtual network
az network vnet create \
  --resource-group <resource-group-name> \
  --name <vnet-name> \
  --address-prefix <address-prefix>

# Create a subnet
az network vnet subnet create \
  --resource-group <resource-group-name> \
  --vnet-name <vnet-name> \
  --name <subnet-name> \
  --address-prefix <subnet-prefix>
```

---

## Kubernetes (AKS)

```sh
# Create an AKS cluster
az aks create \
  --resource-group <resource-group-name> \
  --name <aks-cluster-name> \
  --node-count 3 \
  --enable-addons monitoring \
  --generate-ssh-keys

# Get credentials for an AKS cluster
az aks get-credentials --resource-group <resource-group-name> --name <aks-cluster-name>

# List AKS clusters
az aks list --output table
```

---

## Monitoring

```sh
# List available metrics for a resource
az monitor metrics list-definitions --resource <resource-id>

# View metrics for a resource
az monitor metrics list --resource <resource-id> --metric <metric-name>
```

---

## Helpful Commands

```sh
# Check Azure CLI version
az version

# Show available regions
az account list-locations --output table
```