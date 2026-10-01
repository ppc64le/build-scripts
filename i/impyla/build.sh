#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : conda.recipe
# Version       : v1.0.0
# Source repo   : https://github.com/org/repo
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Maintainer <maintainer@example.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="conda.recipe"
PACKAGE_VERSION="${1:-v1.0.0}"
PACKAGE_URL="https://github.com/org/repo"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS=""
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# $PYTHON setup.py build
# $PYTHON setup.py install --single-version-externally-managed --record=record.txt

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
