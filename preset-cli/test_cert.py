import requests

response = requests.get(
    "https://superset-sit.coexservices.com.au",
    verify="consolidated-cert.pem"
)
print(response.status_code)

