# dbt Docker Image

Docker image for running dbt Core on AWS ECS Fargate.

## Overview

This repo contains the Docker configuration for dbt. The actual dbt models live in [dataplatform-au-dbt](https://github.com/Eftsure/dataplatform-au-dbt).

## How It Works

1. GitHub Actions triggers on push to `main`
2. Docker build clones `dataplatform-au-dbt` 
3. Image is pushed to ECR
4. ECS/Step Functions run the image

## Manual Build

```bash
export GITHUB_TOKEN=your_pat_here

docker build \
  --secret id=GITHUB_TOKEN,env=GITHUB_TOKEN \
  --platform linux/arm64 \
  -t 535586744073.dkr.ecr.ap-southeast-2.amazonaws.com/dbt-repo:latest .
```

## Local Testing

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions.

## Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Image definition (clones dbt repo at build) |
| `profiles/profiles.yml` | dbt connection config (env vars only) |
| `scripts/entrypoint.sh` | Flexible dbt runner |
| `.github/workflows/` | CI/CD pipeline |
