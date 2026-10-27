#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : alabaster
# Version       : 1.0.0
# Source repo   : https://github.com/sphinx-doc/alabaster
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: alabaster_ubi_9.6.sh
# -----------------------------------------------------------------------------
# WARNING: VERSION NOT CONFIRMED IN PACKAGING AUTHORITY
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="alabaster"
PACKAGE_VERSION="${1:-1.0.0}"
PACKAGE_URL="https://github.com/sphinx-doc/alabaster"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 git make python3 python3-devel python3-pip sudo wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# Package will fail for version <310 for version 1.0.0
NOARCH="true"

# Skipping tests as there are no tests for this package
SKIP_TESTS="true"

source "${SCRIPT_DIR}/../../v2-templates/python.sh"
