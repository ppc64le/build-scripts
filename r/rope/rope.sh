#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : rope
# Version       : 1.14.0
# Source repo   : https://github.com/python-rope/rope
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="rope"
PACKAGE_VERSION="${1:-1.14.0}"
PACKAGE_URL="https://github.com/python-rope/rope"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# Pure-Python package — no compiled extensions
NOARCH="true"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

