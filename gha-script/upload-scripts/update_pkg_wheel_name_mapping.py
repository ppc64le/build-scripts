"""
update_pkg_wheel_name_mapping.py

Checks and updates the pkg_wheel_name_mapping.json file in IBM Cloud Object Storage (COS)
bucket 'ose-power-artifacts-production'.

If WHEEL_NAME is present and differs from PACKAGE_NAME:
1. Downloads pkg_wheel_name_mapping.json from IBM COS.
2. Checks if mapping[PACKAGE_NAME] == WHEEL_NAME.
3. If not present or different, updates it and uploads it back to COS.
"""

import json
import os
import sys
import requests

COS_ENDPOINT = "https://s3.us.cloud-object-storage.appdomain.cloud"
COS_BUCKET = "ose-power-artifacts-production"
MAPPING_FILE_KEY = "pkg_wheel_name_mapping.json"
IAM_TOKEN_URL = "https://iam.cloud.ibm.com/identity/token"


def get_iam_token(api_key: str) -> str:
    payload = {
        "grant_type": "urn:ibm:params:oauth:grant-type:apikey",
        "apikey": api_key,
    }
    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "application/json",
    }
    response = requests.post(IAM_TOKEN_URL, data=payload, headers=headers, timeout=30)
    response.raise_for_status()
    token_data = response.json()
    if "access_token" not in token_data:
        raise RuntimeError(f"Failed to obtain IAM token: {token_data}")
    return token_data["access_token"]


def get_wheel_mapping(token: str) -> dict:
    url = f"{COS_ENDPOINT}/{COS_BUCKET}/{MAPPING_FILE_KEY}"
    headers = {
        "Authorization": f"Bearer {token}",
    }
    response = requests.get(url, headers=headers, timeout=30)
    if response.status_code == 200:
        try:
            return response.json()
        except Exception as e:
            print(f"Warning: Failed to parse existing pkg_wheel_name_mapping.json: {e}. Starting fresh.")
            return {}
    elif response.status_code == 404:
        print("pkg_wheel_name_mapping.json not found in COS. Initializing new mapping.")
        return {}
    else:
        print(f"Warning: GET {url} returned status code {response.status_code}: {response.text}")
        return {}


def upload_wheel_mapping(token: str, mapping_data: dict) -> None:
    url = f"{COS_ENDPOINT}/{COS_BUCKET}/{MAPPING_FILE_KEY}"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    content = json.dumps(mapping_data, indent=2)
    response = requests.put(url, data=content.encode("utf-8"), headers=headers, timeout=30)
    if response.status_code in (200, 204) and "<Error>" not in response.text:
        print("Successfully uploaded updated pkg_wheel_name_mapping.json to COS.")
    else:
        raise RuntimeError(f"Failed to upload pkg_wheel_name_mapping.json. Status: {response.status_code}, Response: {response.text}")


def main() -> None:
    package_name = os.environ.get("PACKAGE_NAME", "").strip().lower()
    wheel_name = os.environ.get("WHEEL_NAME", "").strip().lower()
    api_key = os.environ.get("GHA_CURRENCY_SERVICE_ID_API_KEY", "").strip()

    print(f"Package Name: {package_name}")
    print(f"Wheel Name:   {wheel_name}")

    if not package_name:
        print("PACKAGE_NAME is empty. Skipping wheel mapping update.")
        return

    if not wheel_name:
        print("WHEEL_NAME is not set or empty. Skipping wheel mapping update.")
        return

    if wheel_name == package_name:
        print(f"WHEEL_NAME '{wheel_name}' matches PACKAGE_NAME '{package_name}'. No mapping update needed.")
        return

    if not api_key:
        print("Warning: GHA_CURRENCY_SERVICE_ID_API_KEY not set. Cannot update pkg_wheel_name_mapping.json in COS.")
        return

    print(f"Detected difference: wheel_name '{wheel_name}' vs package_name '{package_name}'")
    print("Fetching IAM access token...")
    token = get_iam_token(api_key)

    print("Fetching current pkg_wheel_name_mapping.json from COS...")
    raw_mapping = get_wheel_mapping(token)
    # Ensure existing mapping keys and values are normalized to lowercase
    mapping = {k.strip().lower(): v.strip().lower() for k, v in raw_mapping.items()}

    current_val = mapping.get(package_name)
    if current_val == wheel_name:
        print(f"Mapping '{package_name}': '{wheel_name}' already exists and is up to date in COS.")
        print("\n--- Current pkg_wheel_name_mapping.json ---")
        print(json.dumps(mapping, indent=2))
        print("----------------------------------\n")
        return

    print(f"Updating mapping: '{package_name}': '{wheel_name}' (was: '{current_val}')")
    mapping[package_name] = wheel_name

    sorted_mapping = {k: mapping[k] for k in sorted(mapping.keys())}

    print("\n--- Updated pkg_wheel_name_mapping.json ---")
    print(json.dumps(sorted_mapping, indent=2))
    print("----------------------------------\n")

    print("Uploading updated pkg_wheel_name_mapping.json to COS...")
    upload_wheel_mapping(token, sorted_mapping)
    print("Wheel mapping synchronization completed successfully.")


if __name__ == "__main__":
    main()
