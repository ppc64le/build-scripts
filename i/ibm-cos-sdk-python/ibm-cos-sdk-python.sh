#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : ibm-cos-sdk
# Version       : 2.16.2
# Source repo   : https://github.com/ibm/ibm-cos-sdk-python
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="ibm-cos-sdk-python"
PACKAGE_VERSION="${1:-2.16.2}"
PACKAGE_URL="https://github.com/ibm/ibm-cos-sdk-python"

NOARCH="true"
PYPI_NAME="ibm-cos-sdk-core"
# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel libffi-devel make openssl-devel python3-devel zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_test_command — smoke-test import only; functional/integration
# tests require live IBM COS credentials (endpoint, API key, bucket) which are
# not available in CI.
# =============================================================================
custom_test_command() {
    log_info "Running import smoke test for ${PACKAGE_NAME}"
    python -c "import ibm_boto3; print('ibm_boto3 version:', ibm_boto3.__version__)"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

