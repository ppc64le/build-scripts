#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : py-filelock
# Version       : 3.18.0
# Source repo   : https://github.com/benediktschmitt/py-filelock
# Tested on     : UBI 9.5
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="py-filelock"
PACKAGE_VERSION="${1:-3.18.0}"
PACKAGE_URL="https://github.com/benediktschmitt/py-filelock"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc-toolset-13 git python-devel python-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# source /opt/rh/gcc-toolset-13/enable
# export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
# pip install pytest pytest-asyncio pytest-tornasync virtualenv pytest-trio pytest-mock

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
