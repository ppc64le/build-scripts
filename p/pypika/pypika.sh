#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pypika
# Version       : v0.51.1
# Source repo   : https://github.com/kayak/pypika
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pypika"
PACKAGE_VERSION="${1:-v0.51.1}"
PACKAGE_URL="https://github.com/kayak/pypika"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc gcc-c++ git python3 python3-devel python3-pip unzip wget zip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test
# Install additional test dependencies before the test suite runs
# =============================================================================
pre_test() {
    log_info "Installing test dependency.."
    pip install parameterized
}


# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"