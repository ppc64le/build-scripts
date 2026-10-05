#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : google-crc32c
# Version       : v1.8.0
# Source repo   : https://github.com/googleapis/python-crc32c
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="google-crc32c"
PACKAGE_VERSION="${1:-v1.8.0}"
PACKAGE_URL="https://github.com/googleapis/python-crc32c"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel cmake make wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

BUILD_DEPS=${BUILD_DEPS:-"crc32c-google:1.1.2"}


# Fallback setuptools version constraint (no constraint in pyproject.toml)
SETUPTOOLS_VERSION="<82"

# =============================================================================
# CALLBACK: custom_test_command 
# =============================================================================
custom_test_command() {
    log_info "Running pytest with import isolation and googletest exclusion"
    python -I -m pytest \
        -o "addopts=" \
        --disable-warnings \
        tests/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

