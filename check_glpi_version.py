import os
import requests
from bs4 import BeautifulSoup

url = "https://glpi-project.org/fr/telecharger-glpi/"
response = requests.get(url)
soup = BeautifulSoup(response.text, 'html.parser')
version_tag = soup.find('p', {'style': 'text-align: center;'})

if not version_tag:
    print("GLPI version tag not found.")
    exit(1)

version_text = version_tag.text.strip()
current_version = version_text.split(" ")[-1]

try:
    with open("last_glpi_version.txt", "r") as f:
        last_version = f.read().strip()
except FileNotFoundError:
    last_version = None

if current_version != last_version:
    print(f"New GLPI version found: {current_version}")
    with open("new_glpi_version.txt", "w") as f:
        f.write(current_version)
    with open("last_glpi_version.txt", "w") as f:
        f.write(current_version)
else:
    print(f"No new version found. Current version is {current_version}.")
    exit(78)
