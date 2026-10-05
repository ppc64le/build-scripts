#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : future
# Version       : v0.18.3
# Source repo   : https://github.com/PythonCharmers/python-future
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: future_ubi_9.3.sh
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="future"
PACKAGE_VERSION="${1:-v0.18.3}"  # PACKAGE_VERSION updated based on pypi_versions.json input file
PACKAGE_URL="https://github.com/PythonCharmers/python-future"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc gcc-c++ git make python python-devel python-pip sudo wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# Custom test command (extracted from original script)
custom_test_command() {
    # TODO: Review and update test commands
    if !(python3 -m tox -e py3); then
}

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# PACKAGE_DIR=python-future
# pip install pytest tox nox
# cd $PACKAGE_DIR
# if !(python3 -m tox -e py3); then

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
