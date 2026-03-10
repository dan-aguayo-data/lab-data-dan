
from download_abn import DownloadAbn
from upload_to_blob import UploadtoBlob
from unzip_file import Unzip
from key_vault import Keyvault
from download_acnc import DownloadACNC
import logging

Keyvault = Keyvault()  # predefined key vault url
DownloadAbn = DownloadAbn()
Unzipper = Unzip()
Uploadder = UploadtoBlob()
DownloadACNC = DownloadACNC()

#Overwrites original paramater with key vault value, to be able to change quick if needed
DownloadAbn.first_zip_file = Keyvault.get_secret("AZF-ABN-EXTRACT-ZIP-PART-2")
DownloadAbn.second_zip_file = Keyvault.get_secret("AZF-ABN-EXTRACT-ZIP-PART-2")
DownloadAbn.web_page_url =  Keyvault.get_secret("AZF-ABN-EXTRACT-DOWNLOAD-URL")
DownloadACNC.csv_file = Keyvault.get_secret("AZF-ACNC-EXTRACT-CSV-FILE-NAME")
DownloadACNC.web_page_url =  Keyvault.get_secret("AZF-ACNC-EXTRACT-DOWNLOAD-URL")
def run_abn_job():
    try:

        ABN_WEBPAGE_URL = DownloadAbn.web_page_url
        ABN_LOCAL_TEMP_PATH = DownloadAbn.temp_directory
        ABN_FIRST_ZIP_FILE = DownloadAbn.first_zip_file
        ABN_SECOND_ZIP_FILE = DownloadAbn.second_zip_file

        print(f"\n[INFO] ABN Key vault Url is: {Keyvault.key_vault_url}", flush=True)
        print(f"\n[INFO] ABN Download Url is: {ABN_WEBPAGE_URL}", flush=True)
        print(f"\n[INFO] ABN Temp dir created at: {ABN_LOCAL_TEMP_PATH}", flush=True)

        ABN_CONNECTION_STRING = Keyvault.get_secret("AZF-ABN-BLOB-CONNECTION-STRING")
        ABN_CONTAINER_NAME = Keyvault.get_secret("AZF-ABN-CONTAINER-NAME")

        print(f"\n[INFO] Starting download function", flush=True)
        DownloadAbn.download_to_temp_directory(ABN_WEBPAGE_URL)

        print(f"\n[INFO] Starting to unzip file: {ABN_FIRST_ZIP_FILE}", flush=True)

        Unzipper.unzip_files(ABN_LOCAL_TEMP_PATH,ABN_FIRST_ZIP_FILE)

        print(f"\n[INFO] Starting to unzip file: {ABN_SECOND_ZIP_FILE}", flush=True)
        Unzipper.unzip_files(ABN_LOCAL_TEMP_PATH,ABN_SECOND_ZIP_FILE)


        print(f"\n[INFO] Starting upload function", flush=True)
        Uploadder.load_files_to_blob_storage(ABN_CONTAINER_NAME, ABN_CONNECTION_STRING, ABN_LOCAL_TEMP_PATH)

        return True

    except:

        logging.error(f"[ERROR]", exc_info=True)

        return False


def run_acnc_job():
    try:

        ACNC_WEBPAGE_URL = DownloadACNC.web_page_url
        ACNC_LOCAL_TEMP_PATH = DownloadACNC.temp_directory
        ACNC_CSV_FILE = DownloadAbn.first_zip_file

        print(f"\n[INFO] ACNC Key vault Url is: {Keyvault.key_vault_url}", flush=True)
        print(f"\n[INFO] ACNC Download Url is: {ACNC_WEBPAGE_URL}", flush=True)
        print(f"\n[INFO] ACNC File to retrieve is: {ACNC_CSV_FILE}", flush=True)
        print(f"\n[INFO] ACNC Temp dir created at: {ACNC_LOCAL_TEMP_PATH}", flush=True)

        ACNC_CONNECTION_STRING = Keyvault.get_secret("AZF-ACNC-BLOB-CONNECTION-STRING")
        ACNC_CONTAINER_NAME = Keyvault.get_secret("AZF-ACNC-CONTAINER-NAME")

        print(f"\n[INFO] Starting download function", flush=True)
        DownloadACNC.download_to_temp_directory(ACNC_WEBPAGE_URL)


        print(f"\n[INFO] Starting upload function", flush=True)
        Uploadder.load_files_to_blob_storage(ACNC_CONTAINER_NAME, ACNC_CONNECTION_STRING, ACNC_LOCAL_TEMP_PATH)

        return True

    except:

        logging.error(f"[ERROR]", exc_info=True)

        return False



if __name__ == "__main__":
    abn_success = run_abn_job()
    acnc_success = run_acnc_job()

    if not abn_success or not acnc_success:
        import sys
        sys.exit(1)

    print("\n[INFO] All jobs completed successfully.", flush=True)


