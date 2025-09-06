import boto3

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    # Source bucket
    source_bucket = event['Records'][0]['s3']['bucket']['name']
    # File key in source bucket
    source_key = event['Records'][0]['s3']['object']['key']
    
    # Destination bucket
    destination_bucket = 'datalake-dan-source-aws-lab'
    
    # Copy object to the destination bucket
    s3_client.copy_object(Bucket=destination_bucket, 
                          CopySource={'Bucket': source_bucket, 'Key': source_key}, 
                          Key=source_key)
    
    # Optionally, delete the file from the source bucket after copying
    # s3_client.delete_object(Bucket=source_bucket, Key=source_key)
