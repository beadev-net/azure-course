# Azure Entra ID

### Enterprise Application

Admin consent endpoint for an enterprise application:
```sh
https://login.microsoftonline.com/{organization}/adminconsent?client_id={client-id}
```

```sh
# List enterprise applications
az ad app list --all --output table

# Create an enterprise application
az ad app create --display-name <app-name> --homepage <homepage-url> --identifier-uris <identifier-uri> --reply-urls <reply-url> --required-resource-accesses <resource-access-json>
```

### Service Principal

```sh
# List service principals
az ad sp list --output table
```


### App Registration

```sh
# List app registrations
az ad app list --all --output table
```

#### API Permissions

**Delegated Permissions:**
- Requerem que um usuário faça login.
- Limitadas pelos privilégios do usuário.
- Usadas para acesso em nome do usuário.

**Application Permissions:**
- Não dependem de um usuário.
- Concedem permissões completas ao aplicativo.
- Usadas para operações automatizadas ou sem usuário (como daemons ou serviços backend).