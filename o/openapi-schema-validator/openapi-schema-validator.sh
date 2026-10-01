#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : openapi-schema-validator
# Version       : 0.6.3
# Source repo   : https://github.com/p1c2u/openapi-schema-validator
# Tested on     : UBI 9.5
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="openapi-schema-validator"
PACKAGE_VERSION="${1:-0.6.3}"
PACKAGE_URL="https://github.com/p1c2u/openapi-schema-validator"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Configuration
# =============================================================================
NOARCH="true"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
