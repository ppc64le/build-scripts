#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : appdirs
# Version       : 1.4.4
# Source repo   : https://github.com/ActiveState/appdirs
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="appdirs"
PACKAGE_VERSION="${1:-1.4.4}"
PACKAGE_URL="https://github.com/ActiveState/appdirs"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

