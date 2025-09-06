
import os
import tempfile
import time
import shutil
import logging
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from azure.functions import HttpRequest, HttpResponse
from azure.keyvault.secrets import SecretClient
from azure.identity import ManagedIdentityCredential, DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
import azure.functions as func



# Helper to retrieve secrets safely
def get_secret(secret_name):
    """
    add secret name and it will return secret value
    """
    try:
        return kv_client.get_secret(secret_name).value
    except Exception as e:
        logging.error(f"Failed to retrieve secret '{secret_name}': {e}")
        return None


def unzip_files(FILE_PATH):
    """
    Function to unzip files
    """
    zip = FILE_PATH + '/' + 'public_split_1_10.zip'
    shutil.unpack_archive(zip, FILE_PATH, "zip")
    time.sleep(100)
    zip1 = FILE_PATH + '/' + 'public_split_11_20.zip'
    shutil.unpack_archive(zip1,FILE_PATH, "zip")
    time.sleep(100)

def download_to_temp_directory(WEBPAGE_URL,TEMP_DIRECTORY):
    """
    Uses webpage url to download and unzip files into a temp folder
    """


    # Set Chrome download preferences
    prefs = {
        "download.default_directory": TEMP_DIRECTORY,
        "directory_upgrade": True
    }

    # Configure Chrome options
    options = Options()
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_experimental_option("prefs", prefs)
    options.add_argument('--disable-gpu')
    options.add_argument('--disable-software-rasterizer')


    print("[INFO] Starting Chrome browser using Selenium Manager...")
    driver = webdriver.Chrome(options=options)
    driver.set_page_load_timeout(30)

    try:
        print("[INFO] Loading page...")
        driver.get(WEBPAGE_URL)

        print("[INFO] Waiting for page to load...")
        WebDriverWait(driver, 15).until(
            EC.presence_of_element_located((By.TAG_NAME, "a"))
        )

        print("\n[INFO] --- All Links on Page ---")
        all_links = driver.find_elements(By.TAG_NAME, "a")
        for link in all_links:
            href = link.get_attribute("href")
            text = link.text.strip()
            if href:
                print(f"Link text: '{text}', href: {href}")
        print("[INFO] --- End of Links ---\n")

        print("[INFO] Locating Part 1 download link...")
        link1 = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//a[contains(@href, 'public_split_1_10.zip')]"))
        )
        link1_href = link1.get_attribute("href")
        if not link1_href.endswith(".zip"):
            raise ValueError("Part 1 link doesn't look like a ZIP file")
        print(f"[INFO] Part 1 link found: {link1_href}")
        driver.get(link1_href)

        time.sleep(2)

        print("[INFO] Locating Part 2 download link...")
        link2 = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.XPATH, "//a[contains(@href, 'public_split_11_20.zip')]"))
        )
        link2_href = link2.get_attribute("href")
        if not link2_href.endswith(".zip"):
            raise ValueError("Part 2 link doesn't look like a ZIP file")
        print(f"[INFO] Part 2 link found: {link2_href}")
        driver.get(link2_href)

        print("[INFO] Waiting for downloads to finish...")
        timeout = time.time() + 480  # 8 minutes max
        while True:
            files = os.listdir(TEMP_DIRECTORY)
            print(f"[DEBUG] Current files: {files}")
            pending = [f for f in files if f.endswith('.crdownload')]
            if not pending:
                break
            if time.time() > timeout:
                raise TimeoutError("Download timed out after 8 minutes")
            time.sleep(2)

        print("\n[INFO] Downloaded files:")
        for f in os.listdir(TEMP_DIRECTORY):
            print(f)

    except Exception as e:
        print(f"[ERROR] {type(e).__name__}: {e}")

    finally:
        driver.quit()
        print("[INFO] Browser closed.")
    print("[INFO] Starting to Unzip Files",flush=True)
    unzip_files(TEMP_DIRECTORY)
    print("[INFO] Files successfully unzipped.",flush=True)

    print("[INFO] Starting blob storage upload.", flush=True)


    connection_string = ""
    container_name = ""

def load_files_to_blob_storage(CONTAINER_NAME,CONNECTION_STRING,TEMP_DIRECTORY):
    """
    Loads files into blob storage by looping through them in the temp directory
    """
    blob_service_client = BlobServiceClient.from_connection_string(CONNECTION_STRING)
    container_client = blob_service_client.get_container_client(container=CONTAINER_NAME)
    blob_list = container_client.list_blobs()
    path_remove = TEMP_DIRECTORY + '/'
    print("[INFO] Deleting previous files in blob container.", flush=True)
    for blob in blob_list:
        print(blob)
        blob_renew = blob_service_client.get_blob_client(container=CONTAINER_NAME, blob=blob.name)
        blob_renew.delete_blob(delete_snapshots="include")
    print("[INFO] Uploading new files in blob container.", flush=True)
    for r, d, f in os.walk(TEMP_DIRECTORY):
        for file in f:
            file_path_on_azure = file  # force flat structure
            file_path_on_local = os.path.join(r, file)
            blob_obj = blob_service_client.get_blob_client(container=CONTAINER_NAME, blob=file_path_on_azure)
            with open(file_path_on_local, "rb") as data:
                blob_obj.upload_blob(data, overwrite=True)
                print("Uploading file ---->", file_path_on_local)
    shutil.rmtree(TEMP_DIRECTORY)

    # return func.HttpResponse(
    #     "Successfully uploaded all the files",
    #     status_code=200
    # )



#Access Key Vault with Managed Identity
# Determine credential based on environment
try:
    # Check if ManagedIdentityClientId is defined (used in Azure)
    client_id = os.environ["ManagedIdentityClientId"]
    credential = ManagedIdentityCredential(client_id=client_id)
except KeyError:
    # Fallback for local development (uses Azure CLI or VS Code login)
    credential = DefaultAzureCredential()
    logging.info("Using DefaultAzureCredential (likely local development)")

# Setup Key Vault client
KEY_VAULT_URL = get_secret("key_vault")
print(KEY_VAULT_URL, flush=True)
kv_client = SecretClient(vault_url=KEY_VAULT_URL, credential=credential)
WEBPAGE_ABN_EXTRACT = 'https://data.gov.au/data/en/dataset/abn-bulk-extract'#get_secret('AZF-ABN-EXTRACT-DOWNLOAD-URL')
print(WEBPAGE_ABN_EXTRACT, flush=True)
# Setup temp directory
TEMP = tempfile.mkdtemp()
print(f"\n[INFO] Temp dir created at: {TEMP}", flush=True)
ABN_CONNECTION_STRING = get_secret("CONNECTION-STRING")
ABN_CONTAINER_NAME = get_secret("AZF-ABN-CONTAINER-NAME")

print(f"\n[INFO] Starting download function", flush=True)
download_to_temp_directory(WEBPAGE_ABN_EXTRACT,TEMP)
print(f"\n[INFO] Starting upload function", flush=True)
load_files_to_blob_storage(ABN_CONTAINER_NAME, ABN_CONNECTION_STRING, TEMP)
