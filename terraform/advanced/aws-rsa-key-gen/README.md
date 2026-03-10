# Snowflake Service Account RSA Key Generator

Single `terraform apply` to create:
1. Secrets Manager secrets for RSA keys
2. Lambda function to generate keys
3. Step Function for easy manual trigger

## Files

```
auto-service-key-gen/
├── providers.tf      # Terraform providers
├── backend.tf        # S3 backend
├── variables.tf      # All variables
├── secrets.tf        # Secrets Manager resources
├── lambda.tf         # Lambda function + layer
├── step_function.tf  # Step Function + notifications
├── outputs.tf        # All outputs
└── lambda/
    ├── handler.py        # Key generation code
    └── requirements.txt  # cryptography library
```

## Deploy

```bash
terraform init
terraform apply
```

## Generate Keys

1. Open AWS Console → Step Functions → `snowflake-key-generator`
2. Click **Start execution**
3. Input:
   ```json
   {"service_account": "svc_dbt", "key_version": "rsa1"}
   ```
4. View result - copy the `alter_user_command` to run in Snowflake

## Service Accounts

| service_account | Snowflake User | Secrets |
|-----------------|----------------|---------|
| `svc_dbt` | SVC_DATA_DBT | `svc_dbt_rsa1`, `svc_dbt_rsa2` |
| `svc_fivetran` | SVC_DATA_FIVETRAN | `svc_fivetran_rsa1`, `svc_fivetran_rsa2` |
| `svc_terraform` | SVC_DATA_TERRAFORM | `svc_terraform_rsa1`, `svc_terraform_rsa2` |
| `svc_powerbi` | SVC_DATA_POWERBI | `svc_powerbi_rsa1`, `svc_powerbi_rsa2` |


