#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : termcolor
# Version       : 2.5.0
# Source repo   : https://github.com/termcolor/termcolor
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="termcolor"
PACKAGE_VERSION="${1:-2.5.0}"
PACKAGE_URL="https://github.com/termcolor/termcolor"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH="true"

# termcolor < 2.0.0 ships no test suite — skip tests for those versions
pkg_ver=(${PACKAGE_VERSION#v})
pkg_ver=(${pkg_ver//./ })
if [[ ${pkg_ver[0]} -lt 2 ]]; then
    SKIP_TESTS="true"
fi

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

