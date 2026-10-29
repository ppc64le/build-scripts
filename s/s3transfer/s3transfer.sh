#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : s3transfer
# Version       : 0.10.4
# Source repo   : https://github.com/boto/s3transfer
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="s3transfer"
PACKAGE_VERSION="${1:-0.10.4}"
PACKAGE_URL="https://github.com/boto/s3transfer"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel.ppc64le"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH="true"

# =============================================================================
# CALLBACK: custom_test_command — Run unit tests while excluding integration and socket tests, as the S3 integration tests require AWS credentials.
# =============================================================================
custom_test_command() {
    log_info "Running ${PACKAGE_NAME} tests (excluding integration)"
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        -k "not integration and not test_socket_disabled"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
