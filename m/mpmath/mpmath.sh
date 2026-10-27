#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : mpmath
# Version       : 1.3.0
# Source repo   : https://github.com/mpmath/mpmath.git
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="mpmath"
PACKAGE_VERSION="${1:-1.3.0}"
PACKAGE_URL="https://github.com/mpmath/mpmath.git"
PACKAGE_AVAILABLE_TAGS="1.3.0"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel gcc gcc-c++ git libffi-devel make openssl-devel python-devel python-pip wget zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Pure Python package - no compilation needed
# =============================================================================
NOARCH="true"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
