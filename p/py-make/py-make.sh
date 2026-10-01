#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : py-make
# Version       : v0.1.2
# Source repo   : https://github.com/tqdm/py-make
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak @ibm.com>
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="py-make"
PACKAGE_VERSION="${1:-v0.1.2}"
PACKAGE_URL="https://github.com/tqdm/py-make"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ git make python3 python3-devel python3-pip wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export SETUPTOOLS_SCM_PRETEND_VERSION=${PACKAGE_VERSION#v}

# =============================================================================
# OPTIONAL: Variables
# =============================================================================
NOARCH="true"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
