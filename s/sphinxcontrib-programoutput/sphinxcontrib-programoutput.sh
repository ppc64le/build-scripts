#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : sphinxcontrib-programoutput
# Version       : 0.18
# Source repo   : https://github.com/NextThought/sphinxcontrib-programoutput
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="sphinxcontrib-programoutput"
PACKAGE_VERSION="${1:-0.18}"
PACKAGE_URL="https://github.com/NextThought/sphinxcontrib-programoutput"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
NOARCH="true"
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

