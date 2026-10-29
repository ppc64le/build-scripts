#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : nodejs-wheel
# Version       : v22.20.0
# Source repo   : https://github.com/njzjz/nodejs-wheel.git
# Tested on     : UBI:9.5
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Soham Badjate <soham.badjate@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="nodejs-wheel"
PACKAGE_VERSION="${1:-v22.20.0}"  # PACKAGE_VERSION updated based on pypi_versions.json input file
PACKAGE_URL="https://github.com/njzjz/nodejs-wheel.git"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc gcc-c++ git make python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# pip install --upgrade pip setuptools wheel

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
