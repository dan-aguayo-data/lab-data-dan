import os
import shutil
from azure.storage.blob import BlobServiceClient



class UploadtoBlob():
    def __init__(self):
        pass



    def load_files_to_blob_storage(self,container_name,connection_string,temp_directory):
        """
        Loads files into blob storage by looping through them in the temp directory
        """

        blob_service_client = BlobServiceClient.from_connection_string(connection_string)
        container_client = blob_service_client.get_container_client(container=container_name)
        blob_list = container_client.list_blobs()
        path_remove = temp_directory + '/'
        print("[INFO] Deleting previous files in blob container.", flush=True)

        for blob in blob_list:
            print(blob)
            blob_renew = blob_service_client.get_blob_client(container=container_name, blob=blob.name)
            blob_renew.delete_blob(delete_snapshots="include")

        print("[INFO] Uploading new files in blob container.", flush=True)

        for r, d, f in os.walk(temp_directory):
            for file in f:
                file_path_on_azure = file  # force flat structure
                file_path_on_local = os.path.join(r, file)
                blob_obj = blob_service_client.get_blob_client(container=container_name, blob=file_path_on_azure)
                with open(file_path_on_local, "rb") as data:
                    blob_obj.upload_blob(data, overwrite=True)
                    print("Uploading file ---->", file_path_on_local)
        shutil.rmtree(temp_directory)