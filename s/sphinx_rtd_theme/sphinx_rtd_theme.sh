#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : sphinx_rtd_theme
# Version       : 3.0.2
# Source repo   : https://github.com/readthedocs/sphinx_rtd_theme
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="sphinx_rtd_theme"
PACKAGE_VERSION="${1:-3.0.2}"
PACKAGE_URL="https://github.com/readthedocs/sphinx_rtd_theme"

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

