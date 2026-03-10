# Complete Setup Guide for dbt Core on ECS

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              YOUR SETUP                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  GitHub Repos:                                                              │
│  ├── Eftsure/dataplatform-au-dbt     (dbt models - your existing repo)     │
│  └── Eftsure/dbt-docker              (Dockerfile + CI - NEW repo)          │
│                                                                             │
│  AWS Resources:                                                             │
│  ├── ECR: dbt-repo                   (Docker images)                        │
│  ├── Secrets Manager: data/snowflake/svc_dbt_rsa1_private                  │
│  ├── ECS Cluster: fargate-dbt-cluster                                      │
│  └── Step Functions: dbt-core-dev-orchestrator                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Step 1: Update Your OIDC IAM Policy

Add ECR permissions to your existing GitHub Actions OIDC role.

### Via AWS Console:
1. Go to **IAM → Roles** → Find your GitHub Actions role
2. Click on the policy attached to it
3. Click **Edit policy** → **JSON**
4. Add these statements (keep your existing ones):

```json
{
    "Sid": "ECRGetAuthToken",
    "Effect": "Allow",
    "Action": [
        "ecr:GetAuthorizationToken"
    ],
    "Resource": "*"
},
{
    "Sid": "ECRPushPull",
    "Effect": "Allow",
    "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories",
        "ecr:DescribeImages"
    ],
    "Resource": "arn:aws:ecr:ap-southeast-2:535586744073:repository/dbt-repo"
}
```

### Via AWS CLI:
```bash
# Get current policy
aws iam get-role-policy --role-name YOUR_GITHUB_ROLE_NAME --policy-name YOUR_POLICY_NAME > current-policy.json

# Edit the JSON to add ECR permissions, then update:
aws iam put-role-policy \
  --role-name YOUR_GITHUB_ROLE_NAME \
  --policy-name YOUR_POLICY_NAME \
  --policy-document file://updated-policy.json
```

---

## Step 2: Create GitHub Personal Access Token (PAT)

The Docker build needs to clone `dataplatform-au-dbt`. Create a PAT:

1. Go to **GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)**
2. Click **Generate new token (classic)**
3. Settings:
   - Note: `dbt-docker-build`
   - Expiration: 90 days (or longer)
   - Scopes: `repo` (full control of private repos)
4. Copy the token (you won't see it again!)

---

## Step 3: Create the dbt-docker Repository

Create a new repo `Eftsure/dbt-docker` with this structure:

```
dbt-docker/
├── .github/
│   └── workflows/
│       └── docker-build.yml
├── profiles/
│   └── profiles.yml
├── scripts/
│   └── entrypoint.sh
├── Dockerfile
├── requirements.txt
├── .gitignore
├── .dockerignore
└── README.md
```

---

## Step 4: Configure GitHub Secrets & Variables

In `Eftsure/dbt-docker` repo:

### Secrets (Settings → Secrets and variables → Actions → Secrets)

| Secret | Value |
|--------|-------|
| `AWS_ROLE_ARN` | `arn:aws:iam::535586744073:role/YOUR_GITHUB_OIDC_ROLE` |
| `AWS_REGION` | `ap-southeast-2` |
| `GH_PAT` | The PAT you created in Step 2 |

### Variables (Settings → Secrets and variables → Actions → Variables)

| Variable | Value |
|----------|-------|
| `AWS_ACCOUNT_ID` | `535586744073` |
| `ECR_REPOSITORY` | `dbt-repo` |

---

## Step 5: Update Terraform Variables

In your Terraform `terraform.tfvars`:

```hcl
# Secrets Manager - your actual secret name
snowflake_secret_name = "data/snowflake/svc_dbt_rsa1_private"

# Snowflake connection
dbt_snowflake_account = "BXNRJRX-XQ57619"
dbt_snowflake_user    = "SVC_DATA_DBT"
dbt_snowflake_role    = "SVC_ROLE_DBT_RW"
dbt_database          = "STAGING_DEV"
dbt_schema            = "DEV"
dbt_warehouse         = "EFT_DATA_DBT_DEFAULT"

# Alert email
alert_email = "daniel.aguayo@eftsure.com"

# ECR
ecr_repository_name = "dbt-repo"
ecr_image_tag       = "latest"
```

---

## Step 6: Deploy Terraform

```bash
cd terraform-dbt
terraform init
terraform plan
terraform apply
```

This creates:
- ECR repository
- ECS cluster + task definition
- Step Functions state machine
- EventBridge schedules
- IAM roles
- VPC/networking

---

## Step 7: Build and Push Docker Image

### Option A: Via GitHub Actions (recommended)
Push to `dbt-docker` repo's main branch → workflow runs automatically

### Option B: Manually (first time or testing)
```bash
# Clone the dbt-docker repo
git clone https://github.com/Eftsure/dbt-docker.git
cd dbt-docker

# Set your GitHub PAT
export GITHUB_TOKEN=ghp_your_token_here

# Login to ECR
aws ecr get-login-password --region ap-southeast-2 | \
  docker login --username AWS --password-stdin 535586744073.dkr.ecr.ap-southeast-2.amazonaws.com

# Build with the secret
docker build \
  --secret id=GITHUB_TOKEN,env=GITHUB_TOKEN \
  --platform linux/arm64 \
  -t 535586744073.dkr.ecr.ap-southeast-2.amazonaws.com/dbt-repo:latest .

# Push
docker push 535586744073.dkr.ecr.ap-southeast-2.amazonaws.com/dbt-repo:latest
```

---

## Step 8: Test Locally

### Prerequisites
- Docker installed
- AWS CLI configured
- Access to clone `dataplatform-au-dbt`

### Get the private key from Secrets Manager
```bash
# Fetch the key and save locally (for testing only!)
aws secretsmanager get-secret-value \
  --secret-id data/snowflake/svc_dbt_rsa1_private \
  --query SecretString \
  --output text > /tmp/test_key.txt
```

### Create local .env file
```bash
cat > .env.local << 'EOF'
DBT_SNOWFLAKE_ACCOUNT=BXNRJRX-XQ57619
DBT_SNOWFLAKE_USER=SVC_DATA_DBT
DBT_SNOWFLAKE_ROLE=SVC_ROLE_DBT_RW
DBT_DATABASE=STAGING_DEV
DBT_SCHEMA=DEV
DBT_WAREHOUSE=EFT_DATA_DBT_DEFAULT
DBT_TARGET=dev
DBT_COMMAND=debug
JOB_NAME=local-test
EOF

# Add the private key (careful with newlines!)
echo "DBT_PRIVATE_KEY=$(cat /tmp/test_key.txt)" >> .env.local
```

### Run locally
```bash
# Test dbt debug (connection test)
docker run --rm --env-file .env.local \
  535586744073.dkr.ecr.ap-southeast-2.amazonaws.com/dbt-repo:latest

# Test running a specific model
docker run --rm --env-file .env.local \
  -e DBT_COMMAND=run \
  -e DBT_SELECT=my_first_dbt_model \
  535586744073.dkr.ecr.ap-southeast-2.amazonaws.com/dbt-repo:latest

# Clean up the key!
rm /tmp/test_key.txt .env.local
```

---

## Step 9: Test in AWS

### Via Step Functions Console
1. Go to **Step Functions → State machines → dbt-core-dev-orchestrator**
2. Click **Start execution**
3. Input:
```json
{
  "job_name": "manual-test",
  "dbt_command": "debug",
  "dbt_select": "",
  "dbt_exclude": "",
  "dbt_full_refresh": "false"
}
```

### Via AWS CLI
```bash
aws stepfunctions start-execution \
  --state-machine-arn "arn:aws:states:ap-southeast-2:535586744073:stateMachine:dbt-core-dev-orchestrator" \
  --input '{"job_name":"cli-test","dbt_command":"run","dbt_select":"my_first_dbt_model","dbt_exclude":"","dbt_full_refresh":"false"}'
```

---

## Checklist

- [ ] OIDC role has ECR permissions added
- [ ] GitHub PAT created with `repo` scope
- [ ] `dbt-docker` repo created with all files
- [ ] GitHub secrets configured (AWS_ROLE_ARN, AWS_REGION, GH_PAT)
- [ ] GitHub variables configured (AWS_ACCOUNT_ID, ECR_REPOSITORY)
- [ ] Terraform variables updated with correct secret name
- [ ] Terraform applied (ECR repo exists)
- [ ] Docker image built and pushed
- [ ] Local test successful
- [ ] Step Functions test successful

---

## Troubleshooting

### "Invalid private key" error
- Check that the key in Secrets Manager is plain text (not JSON)
- Ensure key format is `-----BEGIN PRIVATE KEY-----` (PKCS8, no passphrase)
- Verify no extra whitespace

### GitHub Actions OIDC fails
- Verify role trust policy allows your repo
- Check the role ARN is correct in secrets
- Ensure `id-token: write` permission in workflow

### Docker build fails to clone
- Verify GH_PAT secret is set
- Check PAT has `repo` scope
- Ensure PAT hasn't expired

### ECS task fails to start
- Check CloudWatch logs: `/ecs/dbt-task`
- Verify Secrets Manager permissions in task execution role
- Confirm ECR image exists and is accessible
