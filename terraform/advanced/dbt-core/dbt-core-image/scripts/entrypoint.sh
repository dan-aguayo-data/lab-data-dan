#!/bin/bash
# =============================================================================
# dbt Entrypoint Script
# =============================================================================
# Clones dbt project at runtime and executes dbt commands.
# This allows dbt model changes without rebuilding the Docker image.
#
# Environment Variables:
#   Required:
#     - DBT_PRIVATE_KEY: Snowflake private key (plain text, no passphrase)
#     - DBT_SNOWFLAKE_ACCOUNT, DBT_SNOWFLAKE_USER, DBT_SNOWFLAKE_ROLE
#     - DBT_DATABASE_DEV, DBT_SCHEMA_DEV, DBT_WAREHOUSE
#     - GIT_TOKEN: GitHub PAT for cloning private repo
#   
#   Optional:
#     - DBT_COMMAND: run, test, build, seed, snapshot, debug (default: run)
#     - DBT_SELECT: model selector (default: all)
#     - DBT_EXCLUDE: models to exclude
#     - DBT_FULL_REFRESH: "true" to add --full-refresh
#     - DBT_TARGET: dev, uat, prod (default: dev)
#     - GIT_BRANCH: branch to clone (default: main)
#     - ARTIFACT_BUCKET_NAME: S3 bucket for artifacts
#     - JOB_NAME: identifier for this run
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
PROJECT_DIR="/app/dbt_project"
PROFILES_DIR="/app/profiles"
LOG_PREFIX="[dbt-runner]"
GIT_REPO="https://github.com/Eftsure/dataplatform-au-dbt.git"
GIT_BRANCH="${GIT_BRANCH:-main}"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------
log_info() {
    echo "${LOG_PREFIX} INFO: $1"
}

log_error() {
    echo "${LOG_PREFIX} ERROR: $1" >&2
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo "${LOG_PREFIX} DEBUG: $1"
    fi
}

# -----------------------------------------------------------------------------
# Clone dbt Project from GitHub
# -----------------------------------------------------------------------------
clone_dbt_project() {
    log_info "Cloning dbt project from GitHub (branch: ${GIT_BRANCH})..."
    
    if [[ -z "${GIT_TOKEN:-}" ]]; then
        log_error "GIT_TOKEN environment variable is required"
        exit 1
    fi
    
    # Remove existing project directory if it exists
    rm -rf "$PROJECT_DIR"
    
    # Clone the repo
    git clone --depth 1 --branch "$GIT_BRANCH" \
        "https://${GIT_TOKEN}@github.com/Eftsure/dataplatform-au-dbt.git" \
        "$PROJECT_DIR" 2>&1 | grep -v "^remote:" || true
    
    # Remove .git to save space
    rm -rf "$PROJECT_DIR/.git"
    
    log_info "dbt project cloned successfully"
}

# -----------------------------------------------------------------------------
# Validate Required Environment Variables
# -----------------------------------------------------------------------------
validate_env() {
    log_info "Validating environment variables..."
    
    local required_vars=(
        "DBT_PRIVATE_KEY"
        "DBT_SNOWFLAKE_ACCOUNT"
        "DBT_SNOWFLAKE_USER"
        "DBT_SNOWFLAKE_ROLE"
        "DBT_DATABASE_DEV"
        "DBT_SCHEMA_DEV"
        "DBT_WAREHOUSE"
        "GIT_TOKEN"
    )
    
    local missing=()
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing+=("$var")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required environment variables: ${missing[*]}"
        exit 1
    fi
    
    log_info "All required environment variables present"
}

# -----------------------------------------------------------------------------
# Build dbt Command
# -----------------------------------------------------------------------------
build_dbt_command() {
    local cmd="${DBT_COMMAND:-run}"
    local args=()
    
    # Base command
    args+=("dbt" "$cmd")
    
    # Project and profiles directories
    args+=("--project-dir" "$PROJECT_DIR")
    args+=("--profiles-dir" "$PROFILES_DIR")
    
    # Target environment
    if [[ -n "${DBT_TARGET:-}" ]]; then
        args+=("--target" "$DBT_TARGET")
    fi
    
    # Model selection
    if [[ -n "${DBT_SELECT:-}" ]]; then
        args+=("--select" "$DBT_SELECT")
    fi
    
    # Model exclusion
    if [[ -n "${DBT_EXCLUDE:-}" ]]; then
        args+=("--exclude" "$DBT_EXCLUDE")
    fi
    
    # Full refresh flag
    if [[ "${DBT_FULL_REFRESH:-false}" == "true" ]]; then
        args+=("--full-refresh")
    fi
    
    # Return the command array as a string
    echo "${args[*]}"
}

# -----------------------------------------------------------------------------
# Upload Artifacts to S3
# -----------------------------------------------------------------------------
upload_artifacts() {
    if [[ -z "${ARTIFACT_BUCKET_NAME:-}" ]]; then
        log_info "No ARTIFACT_BUCKET_NAME set, skipping artifact upload"
        return 0
    fi
    
    local target_dir="$PROJECT_DIR/target"
    if [[ ! -d "$target_dir" ]]; then
        log_info "No target directory found, skipping artifact upload"
        return 0
    fi
    
    local timestamp=$(date -u +"%Y-%m-%d/%H-%M-%S")
    local job_name="${JOB_NAME:-manual}"
    local s3_path="s3://${ARTIFACT_BUCKET_NAME}/runs/${job_name}/${timestamp}"
    
    log_info "Uploading artifacts to ${s3_path}..."
    
    aws s3 cp "$target_dir/" "$s3_path/" --recursive --quiet
    
    log_info "Artifacts uploaded successfully"
    
    # Also upload to "latest" for easy access
    local latest_path="s3://${ARTIFACT_BUCKET_NAME}/runs/${job_name}/latest"
    aws s3 rm "$latest_path/" --recursive --quiet 2>/dev/null || true
    aws s3 cp "$target_dir/" "$latest_path/" --recursive --quiet
    
    log_info "Latest artifacts updated at ${latest_path}"
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------
main() {
    log_info "=========================================="
    log_info "dbt Runner Starting"
    log_info "=========================================="
    log_info "Timestamp: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    log_info "Job Name: ${JOB_NAME:-manual}"
    log_info "Target: ${DBT_TARGET:-dev}"
    log_info "Command: ${DBT_COMMAND:-run}"
    log_info "Select: ${DBT_SELECT:-all}"
    log_info "Branch: ${GIT_BRANCH}"
    log_info "=========================================="
    
    # Validate environment
    validate_env
    
    # Clone dbt project
    clone_dbt_project
    
    # Build the dbt command
    local dbt_cmd=$(build_dbt_command)
    log_info "Executing: $dbt_cmd"
    
    # Run dbt and capture exit code
    local exit_code=0
    eval "$dbt_cmd" || exit_code=$?
    
    # Upload artifacts regardless of success/failure
    upload_artifacts || log_error "Artifact upload failed (non-fatal)"
    
    # Log completion
    if [[ $exit_code -eq 0 ]]; then
        log_info "=========================================="
        log_info "dbt completed successfully"
        log_info "=========================================="
    else
        log_error "=========================================="
        log_error "dbt failed with exit code: $exit_code"
        log_error "=========================================="
    fi
    
    exit $exit_code
}

# -----------------------------------------------------------------------------
# Run
# -----------------------------------------------------------------------------
main "$@"
