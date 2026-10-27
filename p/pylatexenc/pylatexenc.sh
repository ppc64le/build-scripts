#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pylatexenc
# Version       : v2.10
# Source repo   : https://github.com/phfaist/pylatexenc
# Tested on     : 9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: pylatexenc_ubi_9.3.sh

# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pylatexenc"
PACKAGE_VERSION="${1:-v2.10}"
PACKAGE_URL="https://github.com/phfaist/pylatexenc"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 git make python3 python3-devel.ppc64le sudo wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# Custom test command (extracted from original script)
custom_test_command() {
    # TODO: Review and update test commands
    (python3 -m tox -e py39) && test_status=0 || test_status=$?
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
