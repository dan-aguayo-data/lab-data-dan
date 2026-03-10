from azure.keyvault.secrets import SecretClient
from azure.identity import ManagedIdentityCredential, DefaultAzureCredential
import logging
import os

KEY_VAULT_URL = "https://url-here/"


class Keyvault():
    def __init__(self):
        try:
            # Check if ManagedIdentityClientId is defined (used in Azure)
            client_id = os.environ["ManagedIdentityClientId"]
            self.credential = ManagedIdentityCredential(client_id=client_id)
            logging.info("Using ManagedIdentityCredential with client ID.")
        except KeyError:
            # Fallback for local development (uses Azure CLI or VS Code login)
            self.credential = DefaultAzureCredential()
            logging.info("Using DefaultAzureCredential (likely local development).")

        self.kv_client = SecretClient(vault_url=KEY_VAULT_URL, credential=self.credential)
        self.key_vault_url = KEY_VAULT_URL

    def get_secret(self,secret_name):
        """
        add secret name and it will return secret value
        """
        try:
            return self.kv_client.get_secret(secret_name).value
        except Exception as e:
            logging.error(f"Failed to retrieve secret '{secret_name}': {e}")
            return None

