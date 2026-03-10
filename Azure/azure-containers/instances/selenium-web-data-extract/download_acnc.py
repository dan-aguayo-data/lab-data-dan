import os
import tempfile
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
import subprocess
import traceback


DOWNLOAD_FILE = ''
WEBPAGE_URL = ''

class DownloadACNC():

    def __init__(self):
        self.temp_directory = tempfile.mkdtemp()
        self.web_page_url = WEBPAGE_URL
        self.csv_file = DOWNLOAD_FILE

    def download_to_temp_directory(self, WEBPAGE_URL):
        """
        Uses webpage url to download files into a temp folder
        """
        print(f"[INFO] Temp download directory is: {self.temp_directory}")


        # Set Chrome download preferences
        prefs = {
            "download.default_directory": self.temp_directory,
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



        print("[INFO] Starting Chrome browser using installed ChromeDriver at /usr/local/bin/chromedriver...")
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

            print("[INFO] Locating download link...")
            link1 = WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.XPATH, f"//a[contains(@href, '{self.csv_file}')]"))
            )
            link1_href = link1.get_attribute("href")
            if not link1_href.endswith(".csv"):
                raise ValueError("Download link doesn't look like a CSV file")
            print(f"[INFO] Part 1 link found: {link1_href}")
            driver.get(link1_href)

            time.sleep(2)


            print("[INFO] Waiting for downloads to finish...")
            timeout = time.time() + 480  # 8 minutes max
            while True:
                files = os.listdir(self.temp_directory)
                print(f"[DEBUG] Current files: {files}")
                pending = [f for f in files if f.endswith('.crdownload')]
                if not pending:
                    break
                if time.time() > timeout:
                    raise TimeoutError("Download timed out after 8 minutes")
                time.sleep(2)

            print("\n[INFO] Downloaded files:")
            for f in os.listdir(self.temp_directory):
                print(f)


        except Exception as e:
            print(f"[ERROR] Exception occurred: {e}")
            traceback.print_exc()
        finally:
            print("[INFO] Closing browser...")
            driver.quit()
