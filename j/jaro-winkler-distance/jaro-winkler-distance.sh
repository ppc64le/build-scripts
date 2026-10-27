#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : jaro-winkler-distance
# Version       : v2.0.0
# Source repo   : https://github.com/nap/jaro-winkler-distance
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="jaro-winkler-distance"
PACKAGE_VERSION="${1:-v2.0.0}"
PACKAGE_URL="https://github.com/nap/jaro-winkler-distance"
PYPI_NAME="pyjarowinkler"
NOARCH="true"
# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""


# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

