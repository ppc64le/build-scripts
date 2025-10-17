from pathlib import Path
import os
from os.path import exists

# Using ppc64le secret for Common DB and OIDC (Not maintained per arch)


IS_SETUP=os.getenv("IS_SETUP")
IS_SETUP=IS_SETUP.lower()
SEND_SLACK_NOTIFICATION = os.getenv("SEND_SLACK_NOTIFICATION")
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

# ... other class variables ...
COMMON_DB_CONNECTION_STRING = None
COMMON_DB_USERNAME = None
COMMON_DB_PASSWORD = None
SHARED_DB_CONNECTION_STRING = "http://129.40.81.56:5984"

# Indicates whether the current operation is user-specific or not. This helps in pointing to the correct database while using existing database Wrapper implementation.
# Set to "True" when the configuration or logic should depend on Common Database
# Set to "False" for generic operations where user-specific context is not required and operation would involve arch specific database.
user_operation= "True"

# Database credential variables
DB_CONNECTION_STRING = None
DB_USERNAME = None
DB_PASSWORD = None

# OIDC variables
OIDC_CLIENT_ID = None
OIDC_CLIENT_SECRET = None
client_id = None
client_secret = None
redirect_uri = None
non_auth_uri = None
oidc_settings = {}

# Slack variables
SLACK_URL = None
SLACK_CURRENCY_PACKAGE_REQUEST_URL = None
SLACK_CI_STATUS_URL = None
SLACK_TRAVIS_BUILD_URL = None

# Bulk Search API
BULK_SEARCH_API = None

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


DISTROS_SUPPORTED = (
"rhel-7server", "rhel-7server_alt", "rhel-8.0server",
"rhel-8server", "rhel-8.1server", "rhel-8.2server",
"rhel-8.3server")


DISTRO_LIST = ['Ubuntu', 'RHEL', 'UBI', 'Alpine', 'SLES']

TRAVIS_DB = "travis-ci-index"
MANAGED_CURRENCY_PACKAGES_FILE = "managed_currency_packages.json"
JENKINS_RELEASE_CONFIG_FILE = "currency_release_jenkins_job_template.xml"
JENKINS_NIGHTLY_CONFIG_FILE = "currency_nightly_jenkins_job_template.xml"
DOCKER_CLOUD_ROOT_NODE = "DockerCloud_Docker_UBI_8.6"
DOCKER_CLOUD_NON_ROOT_NODE = "DockerCloud_Docker_Jenkins_UBI_8.6"

CURRENCY_PACKAGES_DISTRO = "UBI"
CURRENCY_PACKAGES_DISTRO_VERSION = "8.5"
CURRENCY_PACKAGE_RELEASE_JOB_FORMAT = "PSL_Currency_Pipeline_{{}}_{}-{}".format(CURRENCY_PACKAGES_DISTRO, CURRENCY_PACKAGES_DISTRO_VERSION)
CURRENCY_PACKAGE_NIGHTLY_JOB_FORMAT = "PSL_Currency_Nightly_{{}}_{}-{}".format(CURRENCY_PACKAGES_DISTRO, CURRENCY_PACKAGES_DISTRO_VERSION)

NEXUS_URL = 'https://163.69.91.4:8443'
NEXUS_DOCKER_ARTIFACTS_REPO = '/repository/currency-artifacts/docker-details'
NEXUS_CURRENCY_CURRENCY_JOBS_LOG_REPO = '/repository/currency-jobs-logs'
NEXUS_USER = 'currencyuser'
NEXUS_PWD = ''

CLAIR_CONTAINER_HOST = "http://localhost:6060"
CLAIR_CONFIG_FILE = CONFIG_DIR + "config.yaml"

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
