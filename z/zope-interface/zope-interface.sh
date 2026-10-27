#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : zope.interface
# Version       : 8.0
# Source repo   : https://github.com/zopefoundation/zope.interface.git
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="zope.interface"
PACKAGE_VERSION="${1:-8.0}"
PACKAGE_URL="https://github.com/zopefoundation/zope.interface"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 git libffi libffi-devel make ncurses python3 python3-devel python3-pip python3-pytest"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

pre_test() {
    log_info "install test dependenies"
    pip install zope.testing
}
# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
