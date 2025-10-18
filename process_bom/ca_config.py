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

EXCEL_READ_ENGINE = 'openpyxl'
BULK_REQUEST_QUEUE_DB = "bulk_search_queue"
DEFAULT_UI_PORT = "3000"
DEFAULT_SERVER_PORT = "8000"
ENABLE_IBM_AUTH = True
TEST_ENV = False
BACKEND_URL = os.getenv("BACKEND_URL")
TARGET_BRANCH = "master"
# Cloud Object Storage Configuration:
IAM_AUTH_URL = "https://iam.cloud.ibm.com/identity/token"

# Cloud Object Storage
IAM_WRITER_API_KEY = os.environ.get("IAM_WRITER_API_KEY")
SERVICE_INSTANCE_ID = os.environ.get("SERVICE_INSTANCE_ID")

# Github Token
GITHUB_TOKEN = None
GITHUB_TOKEN_EXPIRY_TIME = 0
GITHUB_INSTALLATION_TOKENS = [None, None, None]
GITHUB_TOKEN_EXPIRY_TIMES = [0,0,0]

# Travis Token
TRAVIS_TOKEN_PUBLIC = None

BUILD_SCRIPT_PULL_REQUEST_DB = "build_script_pull_request"
JENKINS_DB = "jenkins"
CURRENCY_METADATA_DB = "currency_metadata"

INPUT_FILES = []
MAX_DB_RECORDS = 5000

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

#ICR INFO
ICR_PASSWD = ""
ICR_UNAME = ""

#QUAY INFO
QUAY_PASSWD = ""
QUAY_UNAME = ""

SCAN_TYPES = ["source", "image"]

ALL_PORTED_PACKAGE_DBS = [
"all_distro_packages",
"managed_currency",
"version_tracker_complete",
#"binary_downloadable_packages",
#"ci_packages",
"rhcc",
#"travis_ci_build_logs"
]

#Github Configuration
GITHUB_URLS_TO_PROCESS_FILE = ""
GITHUB_URLS_TO_PROCESS = ""
FILTERED_GITHUB_URLS_TO_PROCESS = ""
SLUGS_TO_PROCESS = ""
GITHUB_REPOS_API = 'https://api.github.com/repos'
GITHUB_DOWNLOAD_API = 'https://raw.githubusercontent.com/'
MY_GITHUB_ISSUES = "https://api.github.com/user/issues"
DIRECTORY_TO_CLONE = "{}/input/".format(HOME)

# Jfrog credential to access ftp3 distro data on jfrog artifactory repo https://na.artifactory.swg-devops.com/artifactory/sys-linux-power-team-ftp3distro-alpine-local. Jfrog user should have read access to this URL
JFROG_USER = ""
JFROG_TOKEN = ""

# Jenkins Distro Mappings for Stats
DISTRO_MAPPINGS = {
    "RHEL_7": "RHEL-7",
    "RHEL_8.5": "RHEL-8",
    "RHEL_9": "RHEL-9",
    "Ubuntu": "Ubuntu-22",
    "CentOs": "CentOS",
    "SLES": "SLES"
}
# Load key used for decryption of creds in dev environment




