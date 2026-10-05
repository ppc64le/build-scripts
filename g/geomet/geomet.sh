#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : geomet
# Version       : 1.1.0
# Source repo   : https://github.com/geomet/geomet
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="geomet"
PACKAGE_VERSION="${1:-1.1.0}"
PACKAGE_URL="https://github.com/geomet/geomet"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ git libjpeg-devel make openblas openblas-devel python3 python3-devel python3-pip tar wget zip zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"