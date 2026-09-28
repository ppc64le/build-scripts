#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : crontab
# Version       : 1.0.4
# Source repo   : https://github.com/josiahcarlson/parse-crontab.git
# Tested on     : UBI 8.4
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sapana Khemkar
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="crontab"
PACKAGE_VERSION="${1:-1.0.4}"
PACKAGE_URL="https://github.com/josiahcarlson/parse-crontab.git"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc gcc-c++ git make ncurses"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Configuration
# =============================================================================
NOARCH="true"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
