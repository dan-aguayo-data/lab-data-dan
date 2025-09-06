import os
import tempfile
import time
import shutil
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager

# Setup temp directory
temp = tempfile.mkdtemp()
print(f"\n[INFO] Temp dir created at: {temp}")

# Set Chrome download preferences
prefs = {
    "download.default_directory": temp,
    "directory_upgrade": True
}

# Configure Chrome options
chrome_options = webdriver.ChromeOptions()

# Comment this out temporarily for debugging (to see browser)
# chrome_options.add_argument('--headless=new')

chrome_options.add_argument('--no-sandbox')
chrome_options.add_argument('--disable-dev-shm-usage')
chrome_options.add_experimental_option("prefs", prefs)

# Launch Chrome using Service
print("[INFO] Starting Chrome browser...")
service = Service(ChromeDriverManager().install())
driver = webdriver.Chrome(service=service, options=chrome_options)
driver.set_page_load_timeout(30)

try:
    print("[INFO] Loading page...")
    driver.get("https://data.gov.au/data/dataset/abn-bulk-extract")

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
        EC.element_to_be_clickable((By.XPATH, "//a[contains(@href, 'public_split_1_10.zip')]"))
    )
    link1_href = link1.get_attribute("href")
    print(f"[INFO] Part 1 link found: {link1_href}")
    driver.execute_script("window.open(arguments[0]);", link1_href)

    time.sleep(2)

    print("[INFO] Locating Part 2 download link...")
    link2 = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.XPATH, "//a[contains(@href, 'public_split_11_20.zip')]"))
    )
    link2_href = link2.get_attribute("href")
    print(f"[INFO] Part 2 link found: {link2_href}")
    driver.execute_script("window.open(arguments[0]);", link2_href)

    print("[INFO] Waiting for downloads to finish...")
    timeout = time.time() + 120  # 2 minutes max
    while True:
        files = os.listdir(temp)
        print(f"[DEBUG] Current files: {files}")
        pending = [f for f in files if f.endswith('.crdownload')]
        if not pending:
            break
        if time.time() > timeout:
            raise TimeoutError("Download timed out after 2 minutes")
        time.sleep(2)

    print("\n[INFO] Downloaded files:")
    for f in os.listdir(temp):
        print(f)

except Exception as e:
    print(f"[ERROR] {type(e).__name__}: {e}")

finally:
    driver.quit()
    print("[INFO] Browser closed.")
    # Uncomment this if you want to clean up the temp folder
    # shutil.rmtree(temp)
