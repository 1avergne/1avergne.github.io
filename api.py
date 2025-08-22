import requests
import json

url = "https://api.powerbi.com/v1.0/myorg/groups/f2c3e1ea-xxxx-xxxx-xxxx-1069484bccc0/reports/85e17542-xxxx-xxxx-xxxx-7e1db0ac4397/GenerateToken"

payload = json.dumps({
  "accessLevel": "View",
  "identities": [
    {
      "username": "ziha@corp.fr",
      "customData": "ziha@corp.fr",
      "roles": [
        "RLS GROUPEMENT"
      ],
      "datasets": [
        "078204ec-xxxx-xxxx-xxxx-e2537ea0c5d2"
      ]
    }
  ]
})
headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer eyJ0kbBjh3meIhIhW7T7Jcw0FMUwFxbroj6Ng'
}

response = requests.request("POST", url, headers=headers, data=payload)

print(response.text)
