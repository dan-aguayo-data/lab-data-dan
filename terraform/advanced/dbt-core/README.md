# dbt-core Infrastructure

This folder contains the infrastructure for running dbt Core on AWS ECS Fargate with Step Functions orchestration for dbt model execution.

Note this project is not productionalized and can only be run locally to 1 environment. The reason for this is that we are waiting on Cloud dbt approval.

## Folder Structure

```
dbt-core/
├── dbt-core-image/          # Docker image for dbt runner
│   ├── Dockerfile
│   ├── profiles/            # dbt profiles.yml for ECS
│   ├── scripts/             # entrypoint.sh
│   └── requirements.txt
│
├── dbt-core-terraform/      # AWS infrastructure (Terraform)
│   ├── ecs.tf               # ECS cluster, task definition
│   ├── step_functions.tf    # Orchestration
│   ├── iam.tf               # Roles and permissions
│   ├── scheduler.tf         # EventBridge schedules
│   ├── secrets.tf           # Secrets Manager references
│   ├── variables.tf         # Variable definitions
│   ├── terraform.tfvars     # Non-sensitive config
│   ├── load-env.ps1         # Sensitive config (NOT committed)
│   └── OPERATE-DBT-README.md # How to run dbt jobs
│
└── README.md                # This file
```

## Architecture

```
GitHub (dataplatform-au-dbt)     ECR (dbt-repo)
         │                              │
         │ cloned at runtime            │ image pulled
         ▼                              ▼
    ┌─────────────────────────────────────────┐
    │            ECS Fargate Task             │
    │  ┌───────────────────────────────────┐  │
    │  │  1. Clone dbt repo from GitHub    │  │
    │  │  2. Run dbt command               │  │
    │  │  3. Upload artifacts to S3        │  │
    │  └───────────────────────────────────┘  │
    └─────────────────────────────────────────┘
                      │
                      ▼
                 Snowflake
```

## Components

### dbt-core-image (Docker)

Contains the Docker image that runs dbt. The image:

- Installs dbt-core and dbt-snowflake
- Clones the dbt project from GitHub **at runtime** (not build time)
- Runs dbt commands based on environment variables
- Uploads artifacts to S3

**When to rebuild the image:**

| Scenario | Rebuild Required? |
|----------|-------------------|
| New dbt version needed | ✅ Yes |
| Python dependency changed | ✅ Yes |
| entrypoint.sh logic changed | ✅ Yes |
| profiles.yml structure changed | ✅ Yes |

**How to rebuild:**

```powershell
cd dbt-core/dbt-core-image

# Build
docker build --platform linux/arm64 -t dbt-core:local .

# Test locally
$privateKey = aws secretsmanager get-secret-value --secret-id "data/snowflake/svc_dbt_rsa1_private" --query SecretString --output text
$gitToken = aws secretsmanager get-secret-value --secret-id "data/github/classic_token_dan_eft_data_dbt_repo" --query SecretString --output text

docker run --rm `
  ----variables here ---
  dbt-core:local

# Push to ECR
aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin {aws account}.dkr.ecr.ap-southeast-2.amazonaws.com

docker tag dbt-core:local {aws account}.dkr.ecr.ap-southeast-2.amazonaws.com/dbt-repo:latest

docker push {aws account}.dkr.ecr.ap-southeast-2.amazonaws.com/dbt-repo:latest
```

### dbt-core-terraform (Infrastructure)

Contains Terraform configuration for AWS resources:

- **ECS Cluster & Task Definition** - Runs dbt containers
- **Step Functions** - Orchestrates jobs with retries and notifications
- **EventBridge Scheduler** - Cron-based job scheduling
- **IAM Roles** - Permissions for ECS, Step Functions, etc.
- **S3 Bucket** - Stores dbt artifacts
- **SNS Topic** - Alerts on success/failure
- **VPC & Networking** - Private subnets with NAT gateway

**How to deploy changes:**

```powershell
cd dbt-core/dbt-core-terraform

# Load sensitive environment variables like snowflake account
. .\load-env.ps1

# Preview changes
terraform plan

# Apply changes
terraform apply
```

## Sensitive Files (NOT Committed)

These files contain secrets and must be created locally:

| File | Location | Purpose |
|------|----------|---------|
| `load-env.ps1` | dbt-core-terraform/ | Terraform variables (secret names) |
| `.env` | dbt-core-image/ | Local testing only |

### Creating load-env.ps1

Create `dbt-core-terraform/load-env.ps1` 


**Note:** Terraform CI/CD with environment-specific deployments (dev/uat/prod) is planned but not yet implemented. Currently, infrastructure changes are applied manually.


## Day-to-Day Operations

### Running dbt Jobs

See `OPERATE-DBT-README.md` for detailed instructions on:

- Running dbt commands via Step Functions
- Model selectors and examples
- Monitoring and troubleshooting

