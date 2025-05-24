import requests
try:
    response = requests.get(
        "https://superset-sit.coexservices.com.au/",
        verify=False
    )
    print(f"Response Code: {response.status_code}")
except requests.exceptions.SSLError as e:
    print(f"SSL Error: {e}")

