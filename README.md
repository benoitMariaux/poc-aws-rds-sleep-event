``` 
terraform init -upgrade
terraform plan 
terraform apply -auto-approve 
```

# Mysql dump loading
```
DB_HOST=$(terraform output -json | jq -r ".db_host.value")
DB_PORT=$(terraform output -json | jq -r ".db_port.value")
DB_USERNAME=$(terraform output -json | jq -r ".db_username.value")
DB_PASSWORD=$(terraform output -json | jq -r ".db_password.value")
DB_NAME=$(terraform output -json | jq -r ".db_name.value")
```
`mysql -u ${DB_USERNAME} -p${DB_PASSWORD} -h ${DB_HOST} < mysqlsampledatabase.sql`