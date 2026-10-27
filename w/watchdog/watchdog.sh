#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : watchdog
# Version       : v6.0.0
# Source repo   : https://github.com/gorakhargosh/watchdog
# Tested on     : UBI: 9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="watchdog"
PACKAGE_VERSION="${1:-v6.0.0}"  # PACKAGE_VERSION updated based on pypi_versions.json input file
PACKAGE_URL="https://github.com/gorakhargosh/watchdog"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc-toolset-13 git python3 python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: Custom test command
# =============================================================================
pre_test() {
    # Set system limits required for watchdog tests
    ulimit -n 4096
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"