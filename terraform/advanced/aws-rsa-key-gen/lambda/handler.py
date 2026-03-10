"""
Lambda: Generate RSA keys and store in Secrets Manager.

Trigger via Step Functions with input:
{
    "service_account": "svc_dbt",
    "key_version": "rsa1"  // or "rsa2"
}
"""
import json
import boto3
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.backends import default_backend


def generate_rsa_keypair():
    """Generate RSA 2048-bit key pair in PKCS8 PEM format."""
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend()
    )
    
    private_pem = private_key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    ).decode('utf-8')
    
    public_pem = private_key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    ).decode('utf-8')
    
    return private_pem, public_pem


def format_for_snowflake(public_pem: str) -> str:
    """Remove headers and newlines for Snowflake ALTER USER."""
    lines = public_pem.strip().split('\n')
    key_lines = [l for l in lines if not l.startswith('-----')]
    return ''.join(key_lines)


def handler(event, context):
    """
    Generate RSA keys and store in Secrets Manager.
    
    Input:
        service_account: svc_dbt | svc_fivetran | svc_terraform | svc_powerbi
        key_version: rsa1 | rsa2
    """
    secrets = boto3.client('secretsmanager')
    
    service_account = event.get('service_account')
    key_version = event.get('key_version', 'rsa1')
    
    if not service_account:
        raise ValueError("service_account is required")
    
    if key_version not in ('rsa1', 'rsa2'):
        raise ValueError("key_version must be rsa1 or rsa2")
    
    # Secret names - using data/dwh/snowflake/ path
    private_secret = f"data/dwh/snowflake/{service_account}_{key_version}_private"
    public_secret = f"data/dwh/snowflake/{service_account}_{key_version}"
    
    print(f"Generating {key_version} keys for {service_account}")
    
    # Generate keys
    private_pem, public_pem = generate_rsa_keypair()
    snowflake_format = format_for_snowflake(public_pem)
    
    # Store private key
    secrets.put_secret_value(
        SecretId=private_secret,
        SecretString=private_pem
    )
    print(f"Updated: {private_secret}")
    
    # Store public key (both formats)
    secrets.put_secret_value(
        SecretId=public_secret,
        SecretString=json.dumps({
            "pem": public_pem,
            "snowflake_format": snowflake_format
        })
    )
    print(f"Updated: {public_secret}")
    
    # Map service account to Snowflake user
    user_map = {
        "svc_dbt": "SVC_DBT",
        "svc_fivetran": "SVC_FIVETRAN",
        "svc_terraform": "SVC_TERRAFORM",
        "svc_powerbi": "SVC_POWERBI"
    }
    snowflake_user = user_map.get(service_account, service_account.upper())
    
    # Build ALTER USER command
    key_field = "RSA_PUBLIC_KEY" if key_version == "rsa1" else "RSA_PUBLIC_KEY_2"
    alter_command = f"ALTER USER {snowflake_user} SET {key_field} = '{snowflake_format}';"
    
    return {
        "status": "success",
        "service_account": service_account,
        "key_version": key_version,
        "secrets_updated": [private_secret, public_secret],
        "snowflake_user": snowflake_user,
        "alter_user_command": alter_command,
        "message": f"Keys generated for {service_account}. Run the ALTER USER command in Snowflake."
    }
