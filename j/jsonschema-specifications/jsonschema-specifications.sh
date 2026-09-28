#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : jsonschema-specifications
# Version       : v2024.10.1
# Source repo   : https://github.com/python-jsonschema/jsonschema-specifications
# Tested on     : 9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="jsonschema-specifications"
PACKAGE_VERSION="${1:-v2024.10.1}"
PACKAGE_URL="https://github.com/python-jsonschema/jsonschema-specifications"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13 git make python3 python3-devel.ppc64le sudo wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"
PYPI_VERSION="2024.10.1"


# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
