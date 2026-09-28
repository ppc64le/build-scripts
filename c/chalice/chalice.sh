#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : chalice
# Version       : 1.32.0
# Source repo   : https://github.com/aws/chalice
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="chalice"
PACKAGE_VERSION="${1:-1.32.0}"
PACKAGE_URL="https://github.com/aws/chalice"
NOARCH="true"
PYPI_VERSION="1.32.0"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ git libjpeg-devel make python3 python3-devel python3-pip tar wget zip zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_test_command
# =============================================================================
custom_test_command() {
    log_info "Running Chalice Unit and Functional tests..."

    # 1. Target only unit and functional tests
    # 2. Ignore templates, docs, integration, and aws folders
    python3 -m pytest \
        -v \
        -o "addopts=" \
        --ignore=chalice/templates \
        --ignore=docs \
        --ignore=tests/integration \
        --ignore=tests/aws \
        tests/unit tests/functional
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
