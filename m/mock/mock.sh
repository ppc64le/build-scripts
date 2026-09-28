#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : mock
# Version       : 5.2.0
# Source repo   : https://github.com/testing-cabal/mock
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: mock_ubi_9.3.sh
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="mock"
PACKAGE_VERSION="${1:-5.2.0}"
PACKAGE_URL="https://github.com/testing-cabal/mock"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ git libjpeg-devel make python3 python3-devel python3-pip tar wget zip zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
