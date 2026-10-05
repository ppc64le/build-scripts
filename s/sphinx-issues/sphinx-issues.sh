#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : sphinx-issues
# Version       : 5.0.1
# Source repo   : https://github.com/sloria/sphinx-issues
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="sphinx-issues"
PACKAGE_VERSION="${1:-5.0.1}"
PACKAGE_URL="https://github.com/sloria/sphinx-issues"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH="true"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

