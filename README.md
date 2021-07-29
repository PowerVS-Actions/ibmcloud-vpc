# powervs-vms-age
Get all VPC at IBM Cloud

```
add the necessary data in the cloud_accounts:
    cloud_account_number:cloud_account_name,api_key

chmod +x ./vpc.sh; vpc.sh

docker run --rm -v $(pwd)/all.csv:/python/all.csv -v $(pwd)/database.ini:/python/database.ini vpc:latest
```