from pathlib import Path
import os
from os.path import exists

# Using ppc64le secret for Common DB and OIDC (Not maintained per arch)



# The hardware architecture for which the tool is running irrespective of the HW_ARCH of the host machine.
HW_ARCH = os.getenv("HW_ARCH", "power")  # Default to Power
HOME = str(Path(__file__).resolve().parent.parent)


INPUT_DIR = HOME + "/input/"
CONFIG_DIR = HOME + "/config/"
OUTPUT_DIR = HOME + "/output/"
LOG_DIR = HOME + "/logs/"
SBOM_CVE_DIR = HOME + "/sbomcve/"
# Cloud Object Storage Configuration:
IAM_AUTH_URL = "https://iam.cloud.ibm.com/identity/token"

# Cloud Object Storage
IAM_WRITER_API_KEY = os.environ.get("IAM_WRITER_API_KEY")
SERVICE_INSTANCE_ID = os.environ.get("SERVICE_INSTANCE_ID")

CONTAINER_REPO_LIST = ['icr', 'quay']

TRAVIS_TOKEN_ENTERPRISE = ""
TRAVIS_API_URL = "https://api.travis-ci.com/"
TRAVIS_APP_URL = "https://app.travis-ci.com/"

BOM_TOOLS = [
"Trivy",
"Grype",
"Syft",
"Clair",
]
CLOUD_OBJECT_BUCKET_NAME = "ose-power-toolci-bucket-production"
CLOUD_OBJECT_CVE_SBOM_BUCKET = "ose-power-sbom-cve-details-production"
CLOUD_OBJECT_STORAGE_URL = "https://s3.us.cloud-object-storage.appdomain.cloud"
CLOUD_OBJECT_AUTH_ENDPOINT = "https://iam.cloud.ibm.com/identity/token"


SCAN_TYPES = ["source", "image"]






