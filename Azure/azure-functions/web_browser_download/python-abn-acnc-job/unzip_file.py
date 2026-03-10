
import time
import shutil



class Unzip():
    def __init__(self):
        pass



    def unzip_files(self,file_path,file_path_suffix):
        """
        Function to unzip files
        """
        zip = file_path + '/' + file_path_suffix
        shutil.unpack_archive(zip, file_path, "zip")
        time.sleep(100)
