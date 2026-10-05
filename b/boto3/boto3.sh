#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : boto3
# Version       : 1.42.40
# Source repo   : https://github.com/boto/boto3
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="boto3"
PACKAGE_VERSION="${1:-1.42.40}" 
PACKAGE_URL="https://github.com/boto/boto3"
NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 git make python3 python3-devel python3-pip sudo wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_test_command
# =============================================================================
custom_test_command() {
    log_info "Running boto3 unit tests (excluding integration tests)..."

    # --ignore skips the integration folder
    # -o "addopts=" prevents pytest.ini from forcing coverage or other plugins
    python -I -m pytest -v \
        -o "addopts=" \
        --ignore=tests/integration \
        tests/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
