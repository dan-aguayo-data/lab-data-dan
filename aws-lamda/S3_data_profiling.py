import boto3
import csv
from io import BytesIO
from datetime import datetime

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    source_key = event['Records'][0]['s3']['object']['key']
    destination_bucket = 'datalake-lab-aws-dan'

    # Copy object to the destination bucket
    s3_client.copy_object(Bucket=destination_bucket, 
                          CopySource={'Bucket': source_bucket, 'Key': source_key}, 
                          Key=source_key)

    # Read the file and perform basic profiling
    response = s3_client.get_object(Bucket=source_bucket, Key=source_key)
    content = response['Body'].read().decode('utf-8')
    reader = csv.reader(content.splitlines())
    rows = list(reader)
    
    num_rows = len(rows)
    num_columns = len(rows[0]) if rows else 0

    # Create a simple log entry
    log_entry = f"File Processed: {source_key}, Rows: {num_rows}, Columns: {num_columns}, Time: {datetime.now().isoformat()}"

    # Define log file key
    log_key = f'log/{source_key}-log.txt'

    # Write log data to S3 in the log folder
    s3_client.put_object(Body=log_entry, Bucket=destination_bucket, Key=log_key)

    # Optionally, delete the file from the source bucket after copying
    # s3_client.delete_object(Bucket=source_bucket, Key=source_key)
