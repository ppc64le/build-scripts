#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : traitlets
# Version       : v5.7.1
# Source repo   : https://github.com/ipython/traitlets
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="traitlets"
PACKAGE_VERSION="${1:-v5.7.1}"
PACKAGE_URL="https://github.com/ipython/traitlets"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 git make python3 python3-devel.ppc64le sudo wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
