# Snowflake Terraform Infrastructure

## 📋 Overview

This project manages Snowflake infrastructure using Terraform with a **global + environment-specific** architecture pattern.

## 🏗️ Architecture

### Global Resources (Shared Across All Environments)

**Location:** `snowflake/global/`

**What's Global:**
- ✅ **Service Account Roles** - `SVC_ROLE_DBT_RW`, `SVC_ROLE_FIVETRAN_RW`, `SVC_ROLE_POWERBI_RO`
- ✅ **Warehouses** - Compute warehouses (Analytics, ETL, etc.)
- ✅ **Users** - Service accounts for dbt, Fivetran, Power BI
- ✅ **Network Policies** - IP whitelisting and access controls
- ✅ **Resource Monitors** - Cost control and credit limits

**Why Global?**
These resources are shared by all environments (DEV/UAT/PROD) and should be deployed once.

---

### Environment-Specific Resources

**Location:** `snowflake/environments/{dev|uat|prod}/`

**What's Environment-Specific:**
- ✅ **Databases** - `STAGING_DEV`, `DWH_MART_UAT`, etc.
- ✅ **Schemas** - All schemas within databases
- ✅ **Analyst Roles** - `SF_DATA_ANALYST_DEV_RO`, `SF_DATA_ANALYST_UAT_RO`
- ✅ **Grants** - Permissions to databases, schemas, and objects
- ✅ **Data Retention** - Can vary by environment (1 day in DEV, 7 days in PROD)

**Why Environment-Specific?**
These resources are isolated per environment with different configurations and permissions.

---

## 📁 Project Structure

```
snowflake/
├── .gitignore                    # Git ignore patterns
├── README_PROJECT.md             # This file
├── README_GRANTS.md              # Grant management guide
├── README_DATABASES.md           # Database management guide
├── README_SERVICE_ACCOUNT.md     # Service account guide
│
├── global/                       # Global resources (deployed once)
│   ├── main.tf                   # Main configuration
│   ├── providers.tf              # Provider configuration
│   ├── variables.tf              # Input variables
│   ├── outputs.tf                # Output values
│   ├── backend.tf                # S3 backend configuration
│   ├── service_accounts.tf       # Service account roles
│   ├── warehouses.tf             # Compute warehouses
│   └── network_policies.tf       # Network policies
│
├── environments/
│   ├── dev/                      # DEV environment
│   │   ├── main.tf               # Calls environment module
│   │   ├── providers.tf          # Provider setup
│   │   ├── backend.tf            # State configuration
│   │   ├── variables.tf          # Variable declarations
│   │   └── terraform.tfvars      # DEV-specific values
│   │
│   ├── uat/                      # UAT environment
│   │   └── [same structure]
│   │
│   └── prod/                     # PROD environment
│       └── [same structure]
│
└── modules/
    └── snowflake_environment/    # Reusable environment module
        ├── databases.tf          # Database & schema creation
        ├── grants_service_accounts.tf
        ├── grants_analyst_roles.tf
        ├── grants_all_to_sysadmin.tf
        ├── variables.tf
        └── outputs.tf
```

---

## 🚀 Deployment Flow

### Order of Operations

```
1. Deploy Global (ONCE)
   ↓
2. Deploy DEV
   ↓
3. Deploy UAT
   ↓
4. Deploy PROD
```

**⚠️ CRITICAL:** Global **must** be deployed before any environment!

---

## 🔄 CI/CD Workflows

### GitHub Actions

**Manual Triggers Only** - No automatic deployments

#### Available Workflows:

1. **Snowflake - Terraform Plan**
   - Select environment: `global`, `dev`, `uat`, `prod`
   - Shows what will change
   - No changes applied

2. **Snowflake - Terraform Apply**
   - Select environment: `global`, `dev`, `uat`, `prod`
   - Applies changes
   - PROD requires manual approval

#### Safety Features:

✅ **Global Dependency Check** - Environments cannot be deployed if global has pending changes
✅ **Production Approval** - PROD deployments require manual approval from authorized users
✅ **Plan Artifacts** - All plans are saved for audit trail

---

## 💻 Local Development & Testing

### Prerequisites

1. **Terraform** (v1.9.6+)
2. **AWS CLI** - Configured with access to secrets
3. **PowerShell** - For local environment setup

### Local Testing

To test locally, you'll need a PowerShell environment file (`.env.ps1`) containing your Snowflake credentials and AWS configuration. This file is **git-ignored** and should never be committed.

**Steps:**

```powershell
# 1. Navigate to the directory
cd snowflake/global  # or snowflake/environments/dev

# 2. Source your environment file
. ./your-env-file.env.ps1  # Your local credentials

# 3. Initialize Terraform
terraform init

# 4. Validate configuration
terraform validate

# 5. Plan changes
terraform plan -out=tfplan

# 6. Apply (if safe)
terraform apply tfplan
```

**Note:** Never run `terraform apply` locally against PROD without explicit approval!

---

## 🔐 Secrets Management

All secrets are stored in **AWS Secrets Manager**:

- ✅ Snowflake private key for service account authentication
- ✅ Retrieved automatically by Terraform via AWS provider
- ✅ Never stored in code or state files

**Secrets Used:**
```
/snowflake/terraform/private-key          # Terraform service account private key
```

---

## 🏷️ Naming Conventions

### Databases
```
{DATABASE_NAME}_{ENVIRONMENT}
Examples: STAGING_DEV, DWH_MART_UAT, LANDING_FP_PROD
```

### Service Account Roles (Global)
```
SVC_ROLE_{SERVICE}_{PERMISSION}
Examples: SVC_ROLE_DBT_RW, SVC_ROLE_POWERBI_RO
```

### Analyst Roles (Environment-Specific)
```
SF_DATA_ANALYST_{ENVIRONMENT}_{PERMISSION}
Examples: SF_DATA_ANALYST_DEV_RO, SF_DATA_ANALYST_PROD_RO
```

### Warehouses (Global)
```
{PURPOSE}_{SIZE}
Examples: EFT_DATA_ANALYTICS, EFT_DATA_ETL
```

---

## 📊 State Management

**Backend:** AWS S3 + DynamoDB

**State Files:**
```
s3://your-bucket/snowflake/global/terraform.tfstate
s3://your-bucket/snowflake/environments/dev/terraform.tfstate
s3://your-bucket/snowflake/environments/uat/terraform.tfstate
s3://your-bucket/snowflake/environments/prod/terraform.tfstate
```

**Why Separate States?**
- ✅ Isolated blast radius
- ✅ Independent deployments
- ✅ Environment-specific locking
- ✅ Easier rollbacks

---

## ⚠️ Important Notes

### Global Changes
- Any change to global resources affects **ALL** environments
- Always test global changes in a plan first
- Consider change windows for global deployments

### Environment Dependencies
- Environments depend on global resources via remote state
- Global must be applied before environments
- CI/CD enforces this dependency automatically

### Data Retention
- **DEV:** 1 day (lower cost)
- **UAT:** 7 days (testing)
- **PROD:** 7+ days (compliance)

### Database Lifecycle Protection
- **DEV/UAT:** `prevent_destroy = false` (can be deleted)
- **PROD:** `prevent_destroy = true` (protected from accidental deletion)

---

## 🆘 Troubleshooting

### "Global has pending changes" Error

**Problem:** Trying to deploy environment when global has uncommitted changes

**Solution:**
```bash
# 1. Deploy global first
cd snowflake/global
terraform apply

# 2. Then deploy environment
cd ../environments/dev
terraform apply
```

### "Object does not exist" Errors

**Problem:** Schemas created but grants failing

**Solution:**
```bash
# Just run apply again - Terraform will create missing resources
terraform apply
```

### Timeout Errors

**Problem:** Snowflake API timeouts during grant operations

**Solution:**
- Wait and retry - usually resolves itself
- Check Snowflake status page
- Run `terraform apply` again to continue

---

## 📚 Additional Documentation

- [Grant Management](README_GRANTS.md)
- [Database Management](README_DATABASES.md)
- [Service Account Management](README_SERVICE_ACCOUNT.md)

---

## 🤝 Contributing

1. Create feature branch from `main`
2. Make changes
3. Run `terraform plan` locally
4. Create PR with plan output
5. Get approval
6. Merge to `main`
7. Deploy via GitHub Actions

---

## 📞 Support

For questions or issues:
- **Team:** Data Engineering Team
- **Slack:** #data-engineering
- **Email:** data-team@company.com
