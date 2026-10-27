#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : gunicorn
# Version       : 23.0.0
# Source repo   : https://github.com/benoitc/gunicorn
# Tested on     : UBI 8.7
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="gunicorn"
PACKAGE_VERSION="${1:-23.0.0}"
PACKAGE_URL="https://github.com/benoitc/gunicorn"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc gcc-c++ git make openssl-devel python3.11 python3.11-devel python3.11-pip wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Configuration
# =============================================================================
NOARCH="true"
SKIP_TESTS="true"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
