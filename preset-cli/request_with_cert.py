import requests

try:
    response = requests.get(
        "https://superset-sit.coexservices.com.au/",
        verify="C:/Users/DanielAguayo/lab/preset-cli/venv/Lib/site-packages/certifi/cacert.pem"
    )
    print(f"Response Code: {response.status_code}")
    print(f"Response Text: {response.text}")
except requests.exceptions.SSLError as ssl_error:
    print("SSL Error:", ssl_error)
except requests.exceptions.RequestException as req_error:
    print("Request Error:", req_error)
