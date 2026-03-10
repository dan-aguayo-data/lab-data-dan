"""
Index Maintenance Lambda Function
Connects to SQL Server RDS/EC2 and performs index maintenance directly.
No stored procedures required - all logic is in this file.
"""

import json
import os
import logging
import boto3
import pymssql
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
DB_SECRET_ARN = os.environ.get('DB_SECRET_ARN')
DATABASE_NAME = os.environ.get('DATABASE_NAME')
INCLUDE_TABLES = os.environ.get('INCLUDE_TABLES', '')
EXCLUDE_TABLES = os.environ.get('EXCLUDE_TABLES', '')
PROCEDURE_TIMEOUT_SECONDS = int(os.environ.get('PROCEDURE_TIMEOUT_SECONDS', 300))
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

# =============================================================================
# Configuration for index maintenance
# =============================================================================
FRAGMENTATION_THRESHOLD_REORGANIZE = 10  # Reorganize if > 10%
FRAGMENTATION_THRESHOLD_REBUILD = 30     # Rebuild if > 30%
MIN_PAGE_COUNT = 1000                     # Skip small indexes
ONLINE_REBUILD = False                    # Set True for Enterprise Edition


def get_db_credentials():
    """Retrieve database credentials from Secrets Manager."""
    client = boto3.client('secretsmanager')
    response = client.get_secret_value(SecretId=DB_SECRET_ARN)
    secret = json.loads(response['SecretString'])
    return {
        'host': secret['host'],
        'port': int(secret.get('port', 1433)),
        'database': secret.get('database', DATABASE_NAME),
        'username': secret['username'],
        'password': secret['password']
    }


def get_db_connection(credentials):
    """Create database connection with timeout."""
    return pymssql.connect(
        server=credentials['host'],
        port=credentials['port'],
        user=credentials['username'],
        password=credentials['password'],
        database=credentials['database'],
        timeout=PROCEDURE_TIMEOUT_SECONDS,
        login_timeout=30
    )


def ensure_tables_exist(cursor):
    """Create tracking tables if they don't exist."""
    
    # Create stats table
    cursor.execute("""
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'IndexMaintenanceStats' AND schema_id = SCHEMA_ID('dbo'))
        BEGIN
            CREATE TABLE dbo.IndexMaintenanceStats (
                schema_name NVARCHAR(128),
                table_name NVARCHAR(128),
                index_name NVARCHAR(128),
                avg_fragmentation_in_percent FLOAT,
                page_count BIGINT,
                recommended_action VARCHAR(10),
                LogDate DATETIME DEFAULT GETDATE()
            );
        END
    """)
    
    # Create log table
    cursor.execute("""
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'IndexMaintenanceLog' AND schema_id = SCHEMA_ID('dbo'))
        BEGIN
            CREATE TABLE dbo.IndexMaintenanceLog (
                LogID INT IDENTITY(1,1) PRIMARY KEY,
                LogDate DATETIME DEFAULT GETDATE(),
                SchemaName NVARCHAR(128),
                TableName NVARCHAR(128),
                IndexName NVARCHAR(128),
                ActionTaken VARCHAR(10),
                Command NVARCHAR(MAX),
                ErrorMessage NVARCHAR(MAX) NULL
            );
        END
    """)


def collect_stats(conn):
    """
    Collect index fragmentation stats for specified tables only.
    Uses temp tables for snapshot in heavy write environments.
    """
    cursor = conn.cursor(as_dict=True)
    
    # Ensure tracking tables exist
    ensure_tables_exist(cursor)
    conn.commit()
    
    # Clear previous stats
    cursor.execute("TRUNCATE TABLE dbo.IndexMaintenanceStats")
    conn.commit()
    
    # Get list of tables to check
    if INCLUDE_TABLES:
        tables = [t.strip() for t in INCLUDE_TABLES.split(',') if t.strip()]
    else:
        # No tables specified - skip (safer in heavy write environments)
        logger.warning("No INCLUDE_TABLES specified. Skipping stats collection.")
        return {
            'total_indexes': 0,
            'rebuild_count': 0,
            'reorganize_count': 0,
            'ignore_count': 0,
            'top_fragmented': [],
            'message': 'No tables specified in INCLUDE_TABLES'
        }
    
    # Exclude tables if specified
    if EXCLUDE_TABLES:
        exclude_list = [t.strip().upper() for t in EXCLUDE_TABLES.split(',')]
        tables = [t for t in tables if t.upper() not in exclude_list]
    
    logger.info(f"Checking fragmentation for {len(tables)} tables: {tables}")
    
    # Process each table individually with temp table snapshot
    for table_name in tables:
        try:
            logger.info(f"Collecting stats for table: {table_name}")
            
            # Step 1: Create temp table and snapshot fragmentation stats
            cursor.execute(f"""
                -- Snapshot fragmentation into temp table (fast, consistent read)
                SELECT 
                    ips.object_id,
                    ips.index_id,
                    ips.avg_fragmentation_in_percent,
                    ips.page_count
                INTO #frag_snapshot
                FROM sys.dm_db_index_physical_stats(
                    DB_ID(), 
                    OBJECT_ID('{table_name}'),
                    NULL, 
                    NULL, 
                    'LIMITED'
                ) ips
                WHERE ips.index_id > 0
                    AND ips.page_count > {MIN_PAGE_COUNT}
            """)
            conn.commit()
            
            # Step 2: Insert from temp table with index details
            cursor.execute(f"""
                INSERT INTO dbo.IndexMaintenanceStats (
                    schema_name, table_name, index_name, 
                    avg_fragmentation_in_percent, page_count, recommended_action
                )
                SELECT 
                    OBJECT_SCHEMA_NAME(f.object_id) AS schema_name,
                    OBJECT_NAME(f.object_id) AS table_name,
                    i.name AS index_name,
                    f.avg_fragmentation_in_percent,
                    f.page_count,
                    CASE 
                        WHEN f.avg_fragmentation_in_percent > {FRAGMENTATION_THRESHOLD_REBUILD} THEN 'REBUILD'
                        WHEN f.avg_fragmentation_in_percent > {FRAGMENTATION_THRESHOLD_REORGANIZE} THEN 'REORGANIZE'
                        ELSE 'IGNORE'
                    END AS recommended_action
                FROM #frag_snapshot f
                INNER JOIN sys.indexes i 
                    ON f.object_id = i.object_id 
                    AND f.index_id = i.index_id
                WHERE i.name IS NOT NULL
            """)
            conn.commit()
            
            # Step 3: Drop temp table
            cursor.execute("DROP TABLE #frag_snapshot")
            conn.commit()
            
            logger.info(f"Completed stats for table: {table_name}")
            
        except Exception as e:
            logger.warning(f"Error collecting stats for {table_name}: {str(e)}")
            # Try to clean up temp table if it exists
            try:
                cursor.execute("IF OBJECT_ID('tempdb..#frag_snapshot') IS NOT NULL DROP TABLE #frag_snapshot")
                conn.commit()
            except:
                pass
            continue
    
    # Get summary
    cursor.execute("""
        SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN recommended_action = 'REBUILD' THEN 1 ELSE 0 END) as rebuild_count,
            SUM(CASE WHEN recommended_action = 'REORGANIZE' THEN 1 ELSE 0 END) as reorganize_count,
            SUM(CASE WHEN recommended_action = 'IGNORE' THEN 1 ELSE 0 END) as ignore_count
        FROM dbo.IndexMaintenanceStats
    """)
    summary_row = cursor.fetchone()
    
    # Get top fragmented indexes
    cursor.execute("""
        SELECT TOP 10
            schema_name, table_name, index_name,
            avg_fragmentation_in_percent, page_count, recommended_action
        FROM dbo.IndexMaintenanceStats
        ORDER BY avg_fragmentation_in_percent DESC
    """)
    top_indexes = cursor.fetchall()
    
    cursor.close()
    
    summary = {
        'total_indexes': summary_row['total'] or 0,
        'rebuild_count': summary_row['rebuild_count'] or 0,
        'reorganize_count': summary_row['reorganize_count'] or 0,
        'ignore_count': summary_row['ignore_count'] or 0,
        'top_fragmented': top_indexes
    }
    
    logger.info(f"Stats collected: {summary['total_indexes']} indexes, "
                f"{summary['rebuild_count']} REBUILD, {summary['reorganize_count']} REORGANIZE")
    
    return summary


def perform_maintenance(conn):
    """
    Perform index maintenance (REBUILD/REORGANIZE) based on collected stats.
    Logs all actions to IndexMaintenanceLog table.
    """
    cursor = conn.cursor(as_dict=True)
    
    # Get indexes to maintain
    cursor.execute("""
        SELECT schema_name, table_name, index_name, recommended_action
        FROM dbo.IndexMaintenanceStats
        WHERE recommended_action <> 'IGNORE'
        ORDER BY page_count DESC
    """)
    indexes = cursor.fetchall()
    
    logger.info(f"Starting maintenance on {len(indexes)} indexes...")
    
    success_count = 0
    error_count = 0
    errors = []
    start_time = datetime.now()
    
    for idx in indexes:
        schema_name = idx['schema_name']
        table_name = idx['table_name']
        index_name = idx['index_name']
        action = idx['recommended_action']
        
        # Build the ALTER INDEX command
        if action == 'REBUILD':
            online_option = 'ON' if ONLINE_REBUILD else 'OFF'
            command = f"ALTER INDEX [{index_name}] ON [{schema_name}].[{table_name}] REBUILD WITH (ONLINE = {online_option})"
        else:
            command = f"ALTER INDEX [{index_name}] ON [{schema_name}].[{table_name}] REORGANIZE"
        
        try:
            logger.info(f"Executing: {action} on [{schema_name}].[{table_name}].[{index_name}]")
            cursor.execute(command)
            conn.commit()
            
            # Log success
            cursor.execute("""
                INSERT INTO dbo.IndexMaintenanceLog (SchemaName, TableName, IndexName, ActionTaken, Command)
                VALUES (%s, %s, %s, %s, %s)
            """, (schema_name, table_name, index_name, action, command))
            conn.commit()
            
            success_count += 1
            
        except Exception as e:
            error_msg = str(e)
            logger.warning(f"Error on {index_name}: {error_msg}")
            
            # Log error
            cursor.execute("""
                INSERT INTO dbo.IndexMaintenanceLog (SchemaName, TableName, IndexName, ActionTaken, Command, ErrorMessage)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (schema_name, table_name, index_name, action, command, error_msg))
            conn.commit()
            
            error_count += 1
            errors.append({
                'index': f"{schema_name}.{table_name}.{index_name}",
                'error': error_msg[:200]
            })
    
    cursor.close()
    
    duration_seconds = (datetime.now() - start_time).total_seconds()
    
    summary = {
        'indexes_processed': len(indexes),
        'success_count': success_count,
        'error_count': error_count,
        'duration_seconds': round(duration_seconds, 2),
        'errors': errors[:5]  # First 5 errors
    }
    
    logger.info(f"Maintenance complete: {success_count} success, {error_count} errors, "
                f"duration: {duration_seconds:.2f}s")
    
    return summary


def lambda_handler(event, context):
    """
    Main Lambda handler.
    
    Expected event format:
    {
        "action": "collect_stats" | "perform_maintenance"
    }
    """
    action = event.get('action', 'collect_stats')
    
    logger.info(f"Starting index maintenance action: {action}")
    logger.info(f"Database: {DATABASE_NAME}, Include: {INCLUDE_TABLES}, Exclude: {EXCLUDE_TABLES}")
    logger.info(f"Thresholds: REORGANIZE>{FRAGMENTATION_THRESHOLD_REORGANIZE}%, REBUILD>{FRAGMENTATION_THRESHOLD_REBUILD}%")
    
    try:
        credentials = get_db_credentials()
        conn = get_db_connection(credentials)
        
        if action == 'collect_stats':
            result = collect_stats(conn)
        elif action == 'perform_maintenance':
            result = perform_maintenance(conn)
        else:
            raise ValueError(f"Unknown action: {action}")
        
        conn.close()
        
        response = {
            'statusCode': 200,
            'action': action,
            'database': DATABASE_NAME,
            'timestamp': datetime.now().isoformat(),
            'result': result
        }
        
        logger.info(f"Action completed successfully: {json.dumps(response, default=str)}")
        return response
        
    except pymssql.OperationalError as e:
        error_msg = f"Database connection/operation error: {str(e)}"
        logger.error(error_msg)
        raise Exception(error_msg)
        
    except pymssql.DatabaseError as e:
        error_msg = f"Database error: {str(e)}"
        logger.error(error_msg)
        raise Exception(error_msg)
        
    except Exception as e:
        error_msg = f"Unexpected error: {str(e)}"
        logger.error(error_msg)
        raise
