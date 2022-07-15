from http.client import UNAUTHORIZED
import os
from io import BytesIO
import requests
import xml.etree.ElementTree as ET
import zipfile
import boto3
from pathlib import Path

# https://developer.garmin.com/downloads/connect-iq/sdks/sdks.json

ssm = boto3.client("ssm", region_name="eu-west-1")
ACCESS_TOKEN = ssm.get_parameter(Name="/garmin/access-token", WithDecryption=True)["Parameter"]["Value"]
CIQ_PATH = f"{str(Path.home())}/.Garmin/ConnectIQ"

os.makedirs(f"{CIQ_PATH}/Fonts", exist_ok=True)
os.makedirs(f"{CIQ_PATH}/Devices", exist_ok=True)

devices = requests.get(
    url="https://api.gcs.garmin.com/ciq-product-onboarding/devices",
    headers={"Authorization": f"Bearer {ACCESS_TOKEN}"},
)

if devices.status_code == 401:

    REFRESH_TOKEN = ssm.get_parameter(Name="/garmin/refresh-token", WithDecryption=True)["Parameter"]["Value"]

    oauth = requests.post(
        url="https://services.garmin.com/api/oauth/token",
        data={"grant_type": "refresh_token", "refresh_token": REFRESH_TOKEN, "client_id": "CIQ_SDK_MANAGER"},
    ).json()

    ACCESS_TOKEN = oauth["access_token"]

    ssm.put_parameter(Name="/garmin/refresh-token", Value=oauth["refresh_token"], Overwrite=True)
    ssm.put_parameter(Name="/garmin/access-token", Value=oauth["access_token"], Overwrite=True)

    devices = requests.get(
        url="https://api.gcs.garmin.com/ciq-product-onboarding/devices",
        headers={"Authorization": f"Bearer {ACCESS_TOKEN}"},
    )

devices = devices.json()

fonts = requests.get(
    url="https://api.gcs.garmin.com/ciq-product-onboarding/fonts",
    headers={"Authorization": f"Bearer {ACCESS_TOKEN}"},
).json()

manifest = ET.parse("manifest.xml").getroot()

for product in manifest.findall(".//{http://www.garmin.com/xml/connectiq}product"):
    device = next(device for device in devices if device["name"] == product.attrib["id"])
    if not os.path.exists(f"{CIQ_PATH}/Devices/{device['name']}"):
        print(f"Need to download {device['name']} !")
        request = requests.get(
            url=f"https://api.gcs.garmin.com/ciq-product-onboarding/devices/{device['partNumber']}/ciqInfo",
            headers={"Authorization": f"Bearer {ACCESS_TOKEN}"},
        )

        file = zipfile.ZipFile(BytesIO(request.content))
        file.extractall(f"{CIQ_PATH}/Devices/{device['name']}")

for font in fonts:
    if not os.path.isfile(f"{CIQ_PATH}/Fonts/{font['name']}.cft"):
        print(f"Need to download {font['name']} !")
        request = requests.get(
            url=f"https://api.gcs.garmin.com/ciq-product-onboarding/fonts/font?fontName={font['name']}",
            headers={"Authorization": f"Bearer {ACCESS_TOKEN}"},
        )

        file = zipfile.ZipFile(BytesIO(request.content))
        file.extractall(f"{CIQ_PATH}/Fonts")
