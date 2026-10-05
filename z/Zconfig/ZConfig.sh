#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : ZConfig
# Version       : 4.2
# Source repo   : https://github.com/zopefoundation/ZConfig
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ethan Silverthorne Ethan.Silverthorne@ibm.com
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata (MUST be set)
# =============================================================================
PACKAGE_NAME="ZConfig"
PACKAGE_VERSION="${1:-4.2}"
PACKAGE_URL="https://github.com/zopefoundation/ZConfig"

# =============================================================================
# REQUIRED: Dependencies (at minimum, set RH_DEP_PKGS)
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip gcc"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv gcc"
SLES_DEP_PKGS="git python3 python3-devel python3-pip gcc"

# =============================================================================
# OPTIONAL: Variables
# =============================================================================
NOARCH="true"

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

