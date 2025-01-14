# AZ CLI

[Click Here to Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli#install)

### Global Arguments

```sh
Global Arguments
    --debug                  : Increase logging verbosity to show all debug logs.
    --help -h                : Show this help message and exit.
    --only-show-errors       : Only show errors, suppressing warnings.
    --output -o              : Output format.  Allowed values: json, jsonc, none, table, tsv, yaml,
                               yamlc.  Default: json.
    --query                  : JMESPath query string. See http://jmespath.org/ for more information
                               and examples.
    --verbose                : Increase logging verbosity. Use --debug for full debug logs.
```

### AZ Login

```sh
az login
az login -u <username> -p <password> -t <tenant>
az logout
```

### AZ Token

```sh
TOKEN=$(az account get-access-token --resource https://management.azure.com/ --query accessToken --output tsv)
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

curl -X GET https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourcegroups?api-version=2021-04-01 \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" | jq
```

### Account

```sh
az account list --output table
az account set --subscription "<subscription-id>"
```

> [!NOTE]
> Note: the azcli enable only one user per subscription. If you have multiple users, you need to logout and login with the new user.