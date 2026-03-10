#!/bin/bash
# entrypoint.sh - Connect to remote MSSQL and export tables using BCP
set -euo pipefail

# ============================================
# Configuration from environment variables
# ============================================
REGION="${REGION:-unknown}"
DATA_SOURCE="${DATA_SOURCE:-mssql_exports}"
DATABASE_NAME="${DATABASE_NAME}"
TABLES="${TABLES:-}"  # Empty = export all tables
OUTPUT_BUCKET="${OUTPUT_BUCKET}"
OUTPUT_PREFIX="${OUTPUT_PREFIX:-exports/}"
JOB_ID="${JOB_ID:-export-$(date +%Y%m%d-%H%M%S)}"
BCP_BATCH_SIZE="${BCP_BATCH_SIZE:-10000}"

# Construct hierarchical S3 path: prefix/data_source/region/database/timestamp/
S3_BASE_PATH="${OUTPUT_PREFIX}${DATA_SOURCE}/${REGION}/${DATABASE_NAME}/${JOB_ID}/"

# DB_CREDENTIALS is injected by ECS from Secrets Manager as JSON
if [ -z "${DB_CREDENTIALS:-}" ]; then
    echo "ERROR: DB_CREDENTIALS environment variable is required but not set"
    exit 1
fi

# Parse credentials from JSON
DB_HOST=$(echo "$DB_CREDENTIALS" | jq -r '.host')
DB_PORT=$(echo "$DB_CREDENTIALS" | jq -r '.port')
DB_USER=$(echo "$DB_CREDENTIALS" | jq -r '.username')
DB_PASSWORD=$(echo "$DB_CREDENTIALS" | jq -r '.password')
DB_NAME=$(echo "$DB_CREDENTIALS" | jq -r '.database')

# Override DATABASE_NAME if specified in secrets
if [ -n "$DB_NAME" ] && [ "$DB_NAME" != "null" ]; then
    DATABASE_NAME="$DB_NAME"
fi

LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')] [$REGION]"

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
{"_aws":{"Timestamp":$(date +%s000),"CloudWatchMetrics":[{"Namespace":"DataExport","Dimensions":[["JobId","Region"]],"Metrics":[{"Name":"$metric_name","Unit":"$unit"}]}]},"JobId":"$JOB_ID","Region":"$REGION","$metric_name":$metric_value}
EOF
}

# ============================================
# Validate Configuration
# ============================================
log "Starting job: $JOB_ID"
log "Configuration:"
log "  Data Source: $DATA_SOURCE"
log "  Region: $REGION"
log "  Database: $DATABASE_NAME"
log "  Host: $DB_HOST:$DB_PORT"
log "  User: $DB_USER"
log "  Output: s3://$OUTPUT_BUCKET/${S3_BASE_PATH}"

# ============================================
# Test Network Connectivity
# ============================================
log "Testing connectivity to $DB_HOST:$DB_PORT..."

# DNS resolution check
if ! host "$DB_HOST" &>/dev/null; then
    log_error "DNS resolution failed for $DB_HOST"
    log "Attempting to continue anyway (might be IP address)..."
fi

# Ping check (may not work if ICMP is blocked)
if ping -c 1 -W 2 "$DB_HOST" &>/dev/null; then
    log "✓ ICMP ping successful"
else
    log "⚠ ICMP ping failed (may be blocked by firewall)"
fi

# TCP port check using timeout
if timeout 10 bash -c "cat < /dev/null > /dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
    log "✓ TCP connection to port $DB_PORT successful"
else
    log_error "Cannot establish TCP connection to $DB_HOST:$DB_PORT"
    log_error "Ensure:"
    log_error "  1. ECS tasks are in VPC with VPN connectivity"
    log_error "  2. Security group allows outbound to port $DB_PORT"
    log_error "  3. MSSQL instance accepts connections from this IP"
    log_error "  4. Network ACLs and route tables are configured correctly"
    exit 1
fi

# ============================================
# Test MSSQL Connection
# ============================================
log "Testing MSSQL connection..."

CONNECTION_TEST_RETRIES=5
CONNECTION_TEST_DELAY=10

for i in $(seq 1 $CONNECTION_TEST_RETRIES); do
    if /opt/mssql-tools18/bin/sqlcmd \
        -S "$DB_HOST,$DB_PORT" \
        -U "$DB_USER" \
        -P "$DB_PASSWORD" \
        -d "$DATABASE_NAME" \
        -Q "SELECT 1 AS ConnectionTest" \
        -C \
        -h -1 \
        -W &>/dev/null; then
        log "✓ MSSQL connection successful"
        break
    fi
    
    if [ $i -eq $CONNECTION_TEST_RETRIES ]; then
        log_error "Failed to connect to MSSQL after $CONNECTION_TEST_RETRIES attempts"
        log_error "Common issues:"
        log_error "  1. Invalid credentials in Secrets Manager"
        log_error "  2. Database name '$DATABASE_NAME' doesn't exist"
        log_error "  3. User '$DB_USER' lacks permissions"
        log_error "  4. SQL Server not configured for SQL authentication"
        log_error "  5. Firewall blocking connection"
        exit 1
    fi
    
    log "Connection attempt $i/$CONNECTION_TEST_RETRIES failed, retrying in ${CONNECTION_TEST_DELAY}s..."
    sleep $CONNECTION_TEST_DELAY
done

# ============================================
# Get table list
# ============================================
EXPORT_START_TIME=$(date +%s)

if [ -z "$TABLES" ]; then
    log "Discovering all user tables in database '$DATABASE_NAME'..."
    TABLES=$(/opt/mssql-tools18/bin/sqlcmd \
        -S "$DB_HOST,$DB_PORT" \
        -U "$DB_USER" \
        -P "$DB_PASSWORD" \
        -d "$DATABASE_NAME" \
        -C \
        -h -1 \
        -W \
        -Q "SET NOCOUNT ON; SELECT SCHEMA_NAME(schema_id) + '.' + name FROM sys.tables WHERE is_ms_shipped = 0 ORDER BY name" \
        | tr '\n' ',' | sed 's/,$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [ -z "$TABLES" ]; then
        log_error "No user tables found in database '$DATABASE_NAME'"
        exit 1
    fi
    
    log "Discovered tables: $TABLES"
else
    log "Using specified tables: $TABLES"
fi

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
    S3_KEY="${S3_BASE_PATH}${TABLE_FILE}.csv"
    
    TABLE_EXPORT_START=$(date +%s)
    
    # Get row count for verification
    ROW_COUNT=$(/opt/mssql-tools18/bin/sqlcmd \
        -S "$DB_HOST,$DB_PORT" \
        -U "$DB_USER" \
        -P "$DB_PASSWORD" \
        -d "$DATABASE_NAME" \
        -C \
        -h -1 \
        -W \
        -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM $table" | tr -d '[:space:]')
    
    if ! [[ "$ROW_COUNT" =~ ^[0-9]+$ ]]; then
        log "WARN: Could not determine row count for $table, proceeding anyway..."
        ROW_COUNT=0
    fi
    
    log "  Row count: $ROW_COUNT"
    
    # Export with retry logic
    MAX_RETRIES=3
    RETRY=0
    SUCCESS=false
    
    while [ $RETRY -lt $MAX_RETRIES ] && [ "$SUCCESS" = "false" ]; do
        # BCP export to remote MSSQL server
        if /opt/mssql-tools18/bin/bcp "$DATABASE_NAME.$table" out "$OUTPUT_FILE" \
            -S "$DB_HOST,$DB_PORT;TrustServerCertificate=yes" \
            -U "$DB_USER" \
            -P "$DB_PASSWORD" \
            -c \
            -t "|" \
            -C 65001 \
            -b $BCP_BATCH_SIZE \
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
    
    TABLE_EXPORT_DURATION=$(($(date +%s) - TABLE_EXPORT_START))
    
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
        if aws s3 cp "$OUTPUT_FILE" "s3://$OUTPUT_BUCKET/${S3_KEY}.gz" --only-show-errors; then
            log "✓ SUCCESS: $table"
            log "    Rows: $EXPORTED_ROWS, Size: ${FILE_SIZE_MB}MB (${COMPRESSED_SIZE_MB}MB gzipped)"
            log "    Duration: ${TABLE_EXPORT_DURATION}s"
            log "    S3: s3://$OUTPUT_BUCKET/${S3_KEY}.gz"
            
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

TOTAL_EXPORT_DURATION=$(($(date +%s) - EXPORT_START_TIME))

# ============================================
# Final summary and cleanup
# ============================================
log "=========================================="
log "Export Summary for $REGION"
log "=========================================="
log "Data Source: $DATA_SOURCE"
log "Database: $DATABASE_NAME"
log "Tables processed: $TOTAL_TABLES"
log "  ✓ Succeeded: $EXPORTED"
log "  ✗ Failed: $FAILED"
log "Total rows exported: $TOTAL_ROWS"
log "Total duration: ${TOTAL_EXPORT_DURATION}s"
log "Output location: s3://$OUTPUT_BUCKET/${S3_BASE_PATH}"
log "=========================================="

log_metric "TablesExported" "$EXPORTED"
log_metric "TablesFailed" "$FAILED"
log_metric "TotalRowsExported" "$TOTAL_ROWS"
log_metric "ExportDurationSeconds" "$TOTAL_EXPORT_DURATION" "Seconds"

# Cleanup temp directory
rm -rf /tmp/exports/*

if [ $FAILED -gt 0 ]; then
    log_error "Job completed with $FAILED failures"
    exit 1
fi

log "Job $JOB_ID completed successfully for region $REGION"
