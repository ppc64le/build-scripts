#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : cloudpickle
# Version       : v3.1.1
# Source repo   : https://github.com/cloudpipe/cloudpickle
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cloudpickle"
PACKAGE_VERSION="${1:-v3.1.1}"  # PACKAGE_VERSION updated based on pypi_versions.json input file
PACKAGE_URL="https://github.com/cloudpipe/cloudpickle"
NOARCH="true"
# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ git libjpeg-devel make python3 python3-devel python3-pip tar wget zip zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
