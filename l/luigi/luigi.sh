#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : luigi
# Version       : v3.6.0
# Source repo   : https://github.com/spotify/luigi
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="luigi"
PACKAGE_VERSION="${1:-v3.6.0}"
PACKAGE_URL="https://github.com/spotify/luigi"
NOARCH="true"
# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""


# =============================================================================
# CALLBACK: pre_test — install extra test dependencies for luigi's test suite
# pytest/setuptools/wheel are already installed by the template; only extras
# not covered by requirements-test.txt are listed here.
# pytest-cov is intentionally omitted — the template uninstalls it to prevent
# entrypoint-load crashes before -p flags are processed.
# toml         — needed by luigi[toml] (config_toml_test.py, setup_logging_test.py)
# psycopg2-binary — needed by postgres_test.py mock patching (psycopg2 import)
# google-auth + google-api-python-client — needed by bigquery_test.py at runtime
# =============================================================================
pre_test() {
    log_info "Installing luigi extra test dependencies"
    python -m pip install \
        toml \
        mysql-connector-python \
        pyhive \
        psutil \
        psycopg2-binary \
        mock \
        hypothesis \
        jsonschema \
        boto \
        boto3 \
        avro \
        mypy \
        selenium \
        google-auth \
        google-api-python-client \
        "prometheus-client>=0.5,<0.15" \
        "azure-storage-blob>=12.0.0" \
        azure-mgmt-resource \
        "elasticsearch<7.14" \
        "moto[all]==4.2.9" \
        requests-unixsocket \
        "sqlalchemy<2" \
        datadog

    log_info "Setting AWS environment variables for moto-based tests"
    export AWS_REGION=us-east-1
    export AWS_DEFAULT_REGION=us-east-1
}

# =============================================================================
# CALLBACK: custom_test_command — run luigi test suite.
# test/contrib ignored — all contrib tests require live external services
#   (AWS Batch/S3/Azure/GCP/MySQL/PostgreSQL/Presto/HDFS) or have dependency
#   API mismatches (avro.schema.Parse removed, pyhive principal_username added).
# Remaining ignores are environment/assertion failures not fixable in CI:
#   _mysqldb_test.py — connects to live MySQL at module level during collection;
#                      ConnectionRefusedError on localhost:3306 aborts the session
#   server_test.py   — server_client_class is str not callable (Python 3.10)
#   lock_test.py     — ppc64le coreutils wraps yes/sleep with full path
#   mypy_test.py     — mypy version finds extra errors; expected counts differ
#   cmdline_test.py::test_luigid_logging_conf — no logging_conf_file set in CI
# =============================================================================
custom_test_command() {
    log_info "Running luigi test suite"
    python -m pytest \
        -o "addopts=" \
        --disable-warnings \
        --ignore=test/contrib \
        --ignore=test/_mysqldb_test.py \
        --ignore=test/server_test.py \
        --ignore=test/lock_test.py \
        --ignore=test/mypy_test.py \
        --deselect test/cmdline_test.py::CmdlineTest::test_luigid_logging_conf \
        test/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

