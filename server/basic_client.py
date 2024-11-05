import requests

# The API endpoint
url = "http://127.0.0.1:5000/rooms/1/update"

# Data to be sent
data = {"name": "tomfulp", "x": 69, "y": 420, "costume": "thomas"}

# A POST request to the API
response = requests.post(url, json=data)

# Print the response
print(response)

if response.status_code == 501:
    print(response.json())
