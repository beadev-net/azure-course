# VIRTUAL MACHINE

| DESCRIPTION | LINK                                                                 |
| ----------- | -------------------------------------------------------------------- |
| AZCLI VM    | https://learn.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest |
| CLOUD INIT  | https://cloudinit.readthedocs.io/en/latest/reference/examples.html   |


#### LIST AVAILABLE OS IMAGES
```sh
az vm image list --architecture x64
```

#### LIST SKU SIZES AVAILABLE IN A REGION
```sh
az vm list-skus --location eastus --size Standard_B2ps --all --output table
```

#### INSTALL AZURE MONITOR AGENT (AMA) LOG ANALYTICS WORKSPACE
```sh
sudo vim /etc/nginx/nginx.conf

# add in http block
access_log syslog:server=unix:/dev/log,tag=nginx_access;
error_log syslog:server=unix:/dev/log,tag=nginx_error;

# restart nginx service
sudo systemctl restart nginx

# test syslog output
sudo tail -f /var/log/syslog
```

#### Log Analytics
```kql
Syslog
```