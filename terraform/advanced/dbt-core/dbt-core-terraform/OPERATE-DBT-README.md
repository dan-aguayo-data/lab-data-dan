# dbt Core on AWS ECS with Step Functions

This document explains how to run dbt jobs on AWS ECS Fargate using Step Functions orchestration.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         TRIGGER                                 │
│  EventBridge Scheduler (cron)  OR  Manual (AWS CLI/Console)    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    STEP FUNCTIONS                               │
│  dbt-core-dev-orchestrator                                      │
│  - Runs ECS task                                                │
│  - Handles retries                                              │
│  - Sends success/failure notifications                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ECS FARGATE                                │
│  - Pulls image from ECR                                         │
│  - Fetches secrets from Secrets Manager                        │
│  - Clones dbt repo from GitHub (at runtime)                    │
│  - Runs dbt command                                             │
│  - Uploads artifacts to S3                                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SNOWFLAKE                                  │
│  Executes dbt models/tests                                      │
└─────────────────────────────────────────────────────────────────┘
```

## Running dbt Jobs

### Manual Execution via AWS CLI

```powershell
aws stepfunctions start-execution `
  --state-machine-arn "arn:aws:states:ap-southeast-2:535586744073:stateMachine:dbt-core-dev-orchestrator" `
  --input '{\"job_name\":\"my-job\",\"dbt_command\":\"run\",\"dbt_select\":\"my_model\",\"dbt_exclude\":\"\",\"dbt_full_refresh\":\"false\"}'
```

### Input Parameters

| Parameter | Description | Required | Examples |
|-----------|-------------|----------|----------|
| `job_name` | Identifier for logging and artifacts | Yes | `daily-run`, `staging-refresh` |
| `dbt_command` | The dbt command to execute | Yes | `run`, `test`, `build`, `seed`, `snapshot`, `debug` |
| `dbt_select` | Model selector (--select flag) | No | `my_model`, `tag:daily`, `path:models/staging` |
| `dbt_exclude` | Models to exclude (--exclude flag) | No | `tag:slow`, `my_large_model` |
| `dbt_full_refresh` | Add --full-refresh flag | No | `"true"` or `"false"` |

## dbt Commands

| Command | Description |
|---------|-------------|
| `debug` | Test connection to Snowflake |
| `run` | Execute models |
| `test` | Run tests |
| `build` | Run models + tests in DAG order |
| `seed` | Load CSV seed files |
| `snapshot` | Execute snapshots |

## Model Selectors

### Basic Selectors

| Selector | Description | Example |
|----------|-------------|---------|
| Model name | Single model | `my_model` |
| Multiple models | Space-separated | `model1 model2 model3` |
| Wildcard | Pattern match | `stg_*` |

### Graph Operators

| Selector | Description | Example |
|----------|-------------|---------|
| `+model` | Model + all upstream dependencies | `+dim_customers` |
| `model+` | Model + all downstream dependents | `stg_orders+` |
| `+model+` | Full lineage (upstream + downstream) | `+fct_sales+` |
| `n+model` | Model + n upstream levels | `2+dim_customers` |
| `model+n` | Model + n downstream levels | `stg_orders+1` |

### Tag Selectors

| Selector | Description |
|----------|-------------|
| `tag:daily` | All models with tag "daily" |
| `tag:staging` | All models with tag "staging" |
| `tag:incremental` | All incremental models |

### Path Selectors

| Selector | Description |
|----------|-------------|
| `path:models/staging` | All models in staging folder |
| `path:models/marts/finance` | All models in finance marts |

### Source Selectors

| Selector | Description |
|----------|-------------|
| `source:salesforce` | The salesforce source |
| `source:salesforce+` | Salesforce source + all downstream models |

### Combining Selectors

| Selector | Description |
|----------|-------------|
| `tag:daily,path:models/staging` | Models with tag:daily AND in staging path |
| `tag:daily tag:important` | Models with tag:daily OR tag:important |

## Example Commands

### Run All Models
```json
{
  "job_name": "full-run",
  "dbt_command": "run",
  "dbt_select": "",
  "dbt_exclude": "",
  "dbt_full_refresh": "false"
}
```

### Run Staging Models Only
```json
{
  "job_name": "staging-refresh",
  "dbt_command": "run",
  "dbt_select": "path:models/staging",
  "dbt_exclude": "",
  "dbt_full_refresh": "false"
}
```

### Run Tagged Models
```json
{
  "job_name": "daily-models",
  "dbt_command": "run",
  "dbt_select": "tag:daily",
  "dbt_exclude": "",
  "dbt_full_refresh": "false"
}
```

### Run with Full Refresh
```json
{
  "job_name": "incremental-refresh",
  "dbt_command": "run",
  "dbt_select": "tag:incremental",
  "dbt_exclude": "",
  "dbt_full_refresh": "true"
}
```

### Run Tests Only
```json
{
  "job_name": "test-run",
  "dbt_command": "test",
  "dbt_select": "",
  "dbt_exclude": "",
  "dbt_full_refresh": "false"
}
```

### Build (Run + Test)
```json
{
  "job_name": "build-all",
  "dbt_command": "build",
  "dbt_select": "",
  "dbt_exclude": "",
  "dbt_full_refresh": "false"
}
```

### Run Everything Except Slow Models
```json
{
  "job_name": "fast-run",
  "dbt_command": "run",
  "dbt_select": "",
  "dbt_exclude": "tag:slow",
  "dbt_full_refresh": "false"
}
```

### Run Single Model with Dependencies
```json
{
  "job_name": "customer-lineage",
  "dbt_command": "run",
  "dbt_select": "+dim_customers+",
  "dbt_exclude": "",
  "dbt_full_refresh": "false"
}
```

### Debug Connection
```json
{
  "job_name": "connection-test",
  "dbt_command": "debug",
  "dbt_select": "",
  "dbt_exclude": "",
  "dbt_full_refresh": "false"
}
```

## PowerShell Commands

### Run Staging Models
```powershell
aws stepfunctions start-execution `
  --state-machine-arn "arn:aws:states:ap-southeast-2:535586744073:stateMachine:dbt-core-dev-orchestrator" `
  --input '{\"job_name\":\"staging\",\"dbt_command\":\"run\",\"dbt_select\":\"path:models/staging\",\"dbt_exclude\":\"\",\"dbt_full_refresh\":\"false\"}'
```

### Run Tagged Models with Full Refresh
```powershell
aws stepfunctions start-execution `
  --state-machine-arn "arn:aws:states:ap-southeast-2:535586744073:stateMachine:dbt-core-dev-orchestrator" `
  --input '{\"job_name\":\"incremental-full\",\"dbt_command\":\"run\",\"dbt_select\":\"tag:incremental\",\"dbt_exclude\":\"\",\"dbt_full_refresh\":\"true\"}'
```

### Run All Tests
```powershell
aws stepfunctions start-execution `
  --state-machine-arn "arn:aws:states:ap-southeast-2:535586744073:stateMachine:dbt-core-dev-orchestrator" `
  --input '{\"job_name\":\"all-tests\",\"dbt_command\":\"test\",\"dbt_select\":\"\",\"dbt_exclude\":\"\",\"dbt_full_refresh\":\"false\"}'
```

## Scheduled Jobs

Scheduled jobs are defined in `terraform.tfvars`:

```hcl
dbt_jobs = {
  daily_staging = {
    description         = "Refresh staging models daily"
    dbt_command         = "run"
    dbt_select          = "path:models/staging"
    schedule_expression = "cron(0 21 * * ? *)"  # 8 AM Sydney
    schedule_enabled    = true
    timeout_minutes     = 60
  }

  hourly_incremental = {
    description         = "Hourly incremental refresh"
    dbt_command         = "run"
    dbt_select          = "tag:hourly"
    schedule_expression = "cron(0 * * * ? *)"  # Every hour
    schedule_enabled    = true
    timeout_minutes     = 30
  }
}
```

## Monitoring

### Check Execution Status
```powershell
aws stepfunctions describe-execution --execution-arn "<execution-arn>"
```

### View CloudWatch Logs
```powershell
aws logs tail /ecs/dbt-task --follow
```

### View Recent Logs
```powershell
aws logs tail /ecs/dbt-task --since 30m
```

## Artifacts

dbt artifacts (logs, manifest.json, run_results.json) are uploaded to S3:

```
s3://dbt-artifacts-xxxxx/runs/{job_name}/{timestamp}/
s3://dbt-artifacts-xxxxx/runs/{job_name}/latest/
```

## Limitations

| Limitation | Workaround |
|------------|------------|
| No `--vars` support | Add to entrypoint script if needed |
| No `--defer` support | Add to entrypoint script if needed |
| No command chaining | Use `build` command or separate executions |
| Single target | Set via ECS environment variable |

## Troubleshooting

### Task Fails Immediately
- Check IAM permissions for Secrets Manager
- Verify ECR image exists
- Check CloudWatch logs: `/ecs/dbt-task`

### Connection Failed
- Run with `dbt_command: "debug"` first
- Verify Snowflake credentials in Secrets Manager
- Check security group allows outbound HTTPS

### Model Not Found
- Verify dbt repo has latest code
- Check model name spelling
- Verify tag exists in model config

### Timeout
- Increase `timeout_minutes` in job config
- Check if model is stuck waiting for warehouse
- Consider running fewer models per job
