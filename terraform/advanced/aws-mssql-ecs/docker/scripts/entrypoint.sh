#!/bin/bash
# entrypoint.sh - Main orchestration: find latest .bak, restore, export to S3
set -euo pipefail

# ============================================
# Configuration from environment variables
# ============================================
DB_NAME="${DB_NAME:-RestoredDB}"
BACKUP_BUCKET="${BACKUP_BUCKET}"
BACKUP_PREFIX="${BACKUP_PREFIX:-backups/}"
OUTPUT_BUCKET="${OUTPUT_BUCKET}"
OUTPUT_PREFIX="${OUTPUT_PREFIX:-exports/}"
TABLES="${TABLES:-}"  # Empty = export all tables
JOB_ID="${JOB_ID:-export-$(date +%Y%m%d-%H%M%S)}"

# SA_PASSWORD is injected by ECS from Secrets Manager
if [ -z "${SA_PASSWORD:-}" ]; then
    echo "ERROR: SA_PASSWORD environment variable is required but not set"
    exit 1
fi

# Set MSSQL_SA_PASSWORD for SQL Server startup (must match SA_PASSWORD)
export MSSQL_SA_PASSWORD="$SA_PASSWORD"

LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

# ============================================
# Logging functions
# ============================================
log() {
    echo "$LOG_PREFIX $1"
}

log_error() {
    echo "$LOG_PREFIX ERROR: $1" >&2
}

log_metric() {
    # Emit CloudWatch EMF (Embedded Metric Format) for custom metrics
    local metric_name=$1
    local metric_value=$2
    local unit=${3:-Count}
    
    cat <<EOF
{"_aws":{"Timestamp":$(date +%s000),"CloudWatchMetrics":[{"Namespace":"DataExport","Dimensions":[["JobId"]],"Metrics":[{"Name":"$metric_name","Unit":"$unit"}]}]},"JobId":"$JOB_ID","$metric_name":$metric_value}
EOF
}

# ============================================
# Start SQL Server
# ============================================
log "Starting job: $JOB_ID"
log "Configuration: DB=$DB_NAME, Bucket=$BACKUP_BUCKET, Prefix=$BACKUP_PREFIX"

log "Starting SQL Server..."
/opt/mssql/bin/sqlservr &
SQL_PID=$!

# Wait for SQL Server to be ready
log "Waiting for SQL Server to initialize..."
for i in {1..60}; do
    if /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "SELECT 1" -C &>/dev/null; then
        log "SQL Server is ready"
        break
    fi
    if [ $i -eq 60 ]; then
        log_error "SQL Server failed to start after 60 attempts"
        exit 1
    fi
    sleep 2
done

# ============================================
# Find latest .bak file in S3
# ============================================
log "Searching for latest .bak file in s3://$BACKUP_BUCKET/$BACKUP_PREFIX..."

# List all .bak files and get the most recent one by LastModified
LATEST_BAK=$(aws s3api list-objects-v2 \
    --bucket "$BACKUP_BUCKET" \
    --prefix "$BACKUP_PREFIX" \
    --query 'Contents[?ends_with(Key, `.bak`)] | sort_by(@, &LastModified) | [-1].Key' \
    --output text)

if [ "$LATEST_BAK" == "None" ] || [ -z "$LATEST_BAK" ]; then
    log_error "No .bak files found in s3://$BACKUP_BUCKET/$BACKUP_PREFIX"
    exit 1
fi

log "Found latest backup: $LATEST_BAK"

# Download the backup file
BACKUP_FILE="/var/opt/mssql/backup/$(basename $LATEST_BAK)"
log "Downloading backup to $BACKUP_FILE..."

DOWNLOAD_START=$(date +%s)
aws s3 cp "s3://$BACKUP_BUCKET/$LATEST_BAK" "$BACKUP_FILE" \
  --cli-connect-timeout 60 \
  --cli-read-timeout 300 \
  --no-progress \
  --only-show-errors
DOWNLOAD_DURATION=$(($(date +%s) - DOWNLOAD_START))

log "Download completed in ${DOWNLOAD_DURATION}s"
log_metric "BackupDownloadDurationSeconds" "$DOWNLOAD_DURATION" "Seconds"

# Get file size for logging
BACKUP_SIZE=$(stat -c%s "$BACKUP_FILE")
BACKUP_SIZE_GB=$(echo "scale=2; $BACKUP_SIZE / 1073741824" | bc)
log "Backup file size: ${BACKUP_SIZE_GB} GB"

# ============================================
# Get logical file names from backup
# ============================================
log "Analyzing backup file structure..."

FILELIST=$(/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C -h -1 -W \
    -Q "RESTORE FILELISTONLY FROM DISK = '$BACKUP_FILE'" | grep -E "^[A-Za-z]")

# Extract data and log file names
DATA_FILE=$(echo "$FILELIST" | grep -i "_Data\|_data\|[Dd]ata" | awk '{print $1}' | head -1)
LOG_FILE=$(echo "$FILELIST" | grep -i "_Log\|_log\|[Ll]og" | awk '{print $1}' | head -1)

# Fallback if standard naming not found
if [ -z "$DATA_FILE" ]; then
    DATA_FILE=$(echo "$FILELIST" | head -1 | awk '{print $1}')
fi
if [ -z "$LOG_FILE" ]; then
    LOG_FILE=$(echo "$FILELIST" | tail -1 | awk '{print $1}')
fi

log "Logical files detected: Data=$DATA_FILE, Log=$LOG_FILE"

# ============================================
# Restore database
# ============================================
log "Restoring database $DB_NAME..."

RESTORE_START=$(date +%s)

/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C -Q "
RESTORE DATABASE [$DB_NAME] 
FROM DISK = '$BACKUP_FILE'
WITH 
    MOVE '$DATA_FILE' TO '/var/opt/mssql/data/${DB_NAME}.mdf',
    MOVE '$LOG_FILE' TO '/var/opt/mssql/data/${DB_NAME}_log.ldf',
    REPLACE,
    RECOVERY,
    STATS = 10
" || {
    log_error "Database restore failed"
    exit 1
}

RESTORE_DURATION=$(($(date +%s) - RESTORE_START))
log "Restore completed in ${RESTORE_DURATION}s"
log_metric "RestoreDurationSeconds" "$RESTORE_DURATION" "Seconds"

# Cleanup backup file to save space
rm -f "$BACKUP_FILE"
log "Removed backup file to free ephemeral storage"

# ============================================
# Get table list
# ============================================
if [ -z "$TABLES" ]; then
    log "Discovering all user tables..."
    TABLES=$(/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C \
        -d "$DB_NAME" -h -1 -W \
        -Q "SET NOCOUNT ON; SELECT SCHEMA_NAME(schema_id) + '.' + name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name" \
        | tr '\n' ',' | sed 's/,$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -z "$TABLES" ]; then
        log_error "No user tables found in database"
        exit 1
    fi
fi

log "Tables to export: $TABLES"

# ============================================
# Export tables using BCP
# ============================================
IFS=',' read -ra TABLE_ARRAY <<< "$TABLES"
TOTAL_TABLES=${#TABLE_ARRAY[@]}
EXPORTED=0
FAILED=0
TOTAL_ROWS=0

log "Starting export of $TOTAL_TABLES tables..."

for table in "${TABLE_ARRAY[@]}"; do
    table=$(echo "$table" | xargs)  # Trim whitespace
    [ -z "$table" ] && continue
    
    log "Exporting table: $table ($((EXPORTED + FAILED + 1))/$TOTAL_TABLES)"
    
    # Sanitize table name for filename
    TABLE_FILE=$(echo "$table" | tr '.' '_' | tr -d '[]')
    OUTPUT_FILE="/tmp/exports/${TABLE_FILE}.csv"
    S3_KEY="${OUTPUT_PREFIX}${JOB_ID}/${TABLE_FILE}.csv"
    
    EXPORT_START=$(date +%s)
    
    # Get row count for verification
    ROW_COUNT=$(/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -C \
        -d "$DB_NAME" -h -1 -W \
        -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM $table" | tr -d '[:space:]')
    
    if ! [[ "$ROW_COUNT" =~ ^[0-9]+$ ]]; then
        log "WARN: Could not determine row count for $table, proceeding anyway..."
        ROW_COUNT=0
    fi
    
    # Export with retry logic
    MAX_RETRIES=3
    RETRY=0
    SUCCESS=false
    
    while [ $RETRY -lt $MAX_RETRIES ] && [ "$SUCCESS" = "false" ]; do
        # *** KEY FIX: Add TrustServerCertificate=yes to server connection ***
        if /opt/mssql-tools18/bin/bcp "$DB_NAME.$table" out "$OUTPUT_FILE" \
            -S "localhost;TrustServerCertificate=yes" \
            -U sa \
            -P "$SA_PASSWORD" \
            -c \
            -t "|" \
            -C 65001 \
            -a 32768 \
            -e "/tmp/exports/${TABLE_FILE}_errors.log" 2>&1 | tee /tmp/bcp_output.log; then
            SUCCESS=true
        else
            RETRY=$((RETRY + 1))
            log "WARN: Export failed for $table (attempt $RETRY/$MAX_RETRIES)"
            if [ -f "/tmp/exports/${TABLE_FILE}_errors.log" ]; then
                log "Error details: $(head -5 /tmp/exports/${TABLE_FILE}_errors.log)"
            fi
            sleep 5
        fi
    done
    
    EXPORT_DURATION=$(($(date +%s) - EXPORT_START))
    
    if [ "$SUCCESS" = "true" ] && [ -f "$OUTPUT_FILE" ]; then
        EXPORTED_ROWS=$(wc -l < "$OUTPUT_FILE")
        FILE_SIZE=$(stat -c%s "$OUTPUT_FILE")
        FILE_SIZE_MB=$(echo "scale=2; $FILE_SIZE / 1048576" | bc)
        
        # Gzip the file
        gzip "$OUTPUT_FILE"
        OUTPUT_FILE="${OUTPUT_FILE}.gz"
        COMPRESSED_SIZE=$(stat -c%s "$OUTPUT_FILE")
        COMPRESSED_SIZE_MB=$(echo "scale=2; $COMPRESSED_SIZE / 1048576" | bc)
        
        # Upload to S3
        if aws s3 cp "$OUTPUT_FILE" "s3://$OUTPUT_BUCKET/${S3_KEY}.gz"; then
            log "SUCCESS: $table - $EXPORTED_ROWS rows, ${FILE_SIZE_MB}MB (${COMPRESSED_SIZE_MB}MB gzipped), ${EXPORT_DURATION}s"
            log_metric "RowsExported" "$EXPORTED_ROWS"
            TOTAL_ROWS=$((TOTAL_ROWS + EXPORTED_ROWS))
            
            # Cleanup local file
            rm -f "$OUTPUT_FILE"
            EXPORTED=$((EXPORTED + 1))
        else
            log_error "Failed to upload $table to S3"
            FAILED=$((FAILED + 1))
        fi
    else
        log_error "Failed to export $table after $MAX_RETRIES attempts"
        FAILED=$((FAILED + 1))
    fi
done

# ============================================
# Final summary and cleanup
# ============================================
log "=========================================="
log "Export complete: $EXPORTED/$TOTAL_TABLES tables succeeded, $FAILED failed"
log "Total rows exported: $TOTAL_ROWS"
log "=========================================="

log_metric "TablesExported" "$EXPORTED"
log_metric "TablesFailed" "$FAILED"
log_metric "TotalRowsExported" "$TOTAL_ROWS"

# Shutdown SQL Server gracefully
log "Shutting down SQL Server..."
kill -TERM $SQL_PID 2>/dev/null || true
wait $SQL_PID 2>/dev/null || true

if [ $FAILED -gt 0 ]; then
    log_error "Job completed with failures"
    exit 1
fi

log "Job $JOB_ID completed successfully"