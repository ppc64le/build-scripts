#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : black
# Version       : 26.5.1
# Source repo   : https://github.com/psf/black
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="black"
PACKAGE_VERSION="${1:-26.5.1}"
PACKAGE_URL="https://github.com/psf/black"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel gcc gcc-c++ git libffi-devel make openssl-devel python-devel python-pip wget zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"

# =============================================================================
# CALLBACK: pre_test — Install test dependencies before running tests
# =============================================================================
pre_test() {
    log_info "Installing dependencies for tests"
    python -m pip install -r test_requirements.txt
    python -m pip install "black[d]" "pathspec<0.12" "click>=8.0.0,<8.2.0"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
