#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : dill
# Version       : 0.3.8
# Source repo   : https://github.com/uqfoundation/dill
# Tested on     : UBI: 9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="dill"
PACKAGE_VERSION="${1:-0.3.8}"
PACKAGE_URL="https://github.com/uqfoundation/dill"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc-toolset-13 git python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# Custom test command (extracted from original script)
custom_test_command() {
    python3 -m pip install coverage numpy tox
    tox -e py312
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
