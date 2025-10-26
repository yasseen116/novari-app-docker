import requests
base = "http://127.0.0.1:5000/"
headers = {
    "Content-Type": "application/json"
}
data = {
    "pName": "sticke4",
    "pPrice": 120,
    "description": "cool sticker",
    "availableQuantity":10,
    "sizes": "X",
    "categoryID":1
}
response = requests.delete(base+ "product/4",
headers=headers,
json=data)
print(response.json())
    