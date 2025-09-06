--UNLOAD DATA TO ANOTHER AMAZON RESOURCE 

UNLOAD ('<select_query>')
TO 's3://your-bucket-name/your-prefix/'
IAM_ROLE 'arn:aws:iam::<account-id>:role/<redshift-role>'
FORMAT AS CSV
HEADER
ALLOWOVERWRITE
PARALLEL OFF;
