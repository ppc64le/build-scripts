#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pyphen
# Version       : 0.14.0
# Source repo   : https://github.com/Kozea/Pyphen
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ethan Silverthorne Ethan.Silverthorne@ibm.com
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata (MUST be set)
# =============================================================================
PACKAGE_NAME="${PACKAGE_NAME}"
PACKAGE_VERSION="${1:-0.14.0}"
PACKAGE_URL="https://github.com/Kozea/Pyphen"

# =============================================================================
# REQUIRED: Dependencies (at minimum, set RH_DEP_PKGS)
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip gcc"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv gcc"
SLES_DEP_PKGS="git python3 python3-devel python3-pip gcc"

# =============================================================================
# OPTIONAL VARIABLES
# =============================================================================
NOARCH="true"

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
