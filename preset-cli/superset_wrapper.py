import os
import subprocess

# Set the REQUESTS_CA_BUNDLE environment variable
os.environ['REQUESTS_CA_BUNDLE'] = r"C:\Users\DanielAguayo\lab\preset-cli\certificates\superset-certs.pem"

# Define the superset-cli command
command = [
    "superset-cli",
    "-u", "admin",
    "-p", "e5db2564a7bfce8e",
    "https://superset-sit.coexservices.com.au/",
    "export-assets",
    r"C:\Users\DanielAguayo\lab\preset-cli\extracts\prod"
]

# Run the command
try:
    subprocess.run(command, check=True)
except subprocess.CalledProcessError as e:
    print(f"Command failed with return code {e.returncode}")
