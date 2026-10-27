#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : crc32c
# Version       : 2.8
# Source repo   : https://github.com/ICRAR/crc32c
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : IBM <open-source-automation@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="crc32c"
PACKAGE_VERSION="${1:-2.8}"
PACKAGE_URL="https://github.com/ICRAR/crc32c"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
