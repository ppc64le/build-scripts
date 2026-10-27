#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : python-sdk-core
# Version       : v3.22.1
# Source repo   : https://github.com/IBM/python-sdk-core
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Build Scripts Team <build-scripts@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="python-sdk-core"
PACKAGE_VERSION="${1:-v3.22.1}"
PACKAGE_URL="https://github.com/IBM/python-sdk-core"
PYPI_NAME="ibm-cloud-sdk-core"

NOARCH="true"
SETUPTOOLS_VERSION="<82"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel git libffi-devel make openssl-devel python3-devel python3-pip sudo wget zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test — install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing test dependencies"
    python -m pip install responses pylint 
}

# =============================================================================
# CALLBACK: custom_test_command — run unit tests while skipping integration tests
# =============================================================================
custom_test_command() {
    log_info "Running unit tests (ignoring test_integration which requires live cloud credentials)"
    python -m pytest --import-mode=importlib -o "addopts=" --ignore=test_integration/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

