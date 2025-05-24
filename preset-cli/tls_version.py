import requests
from requests.adapters import HTTPAdapter
from urllib3.util.ssl_ import create_urllib3_context

class ForcedTLSAdapter(HTTPAdapter):
    def __init__(self, *args, **kwargs):
        context = create_urllib3_context()
        context.minimum_version = 2  # TLSv1.2
        kwargs["ssl_context"] = context
        super().__init__(*args, **kwargs)

session = requests.Session()
session.mount("https://", ForcedTLSAdapter())
response = session.get("https://superset-sit.coexservices.com.au")
print(response.status_code)
