#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : mongoengine
# Version       : v0.29.1
# Source repo   : https://github.com/MongoEngine/mongoengine
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="mongoengine"
PACKAGE_VERSION="${1:-v0.29.1}"
PACKAGE_URL="https://github.com/MongoEngine/mongoengine"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="python3 python3-devel python3-pip freetype freetype-devel gcc gcc-c++ git libjpeg-turbo libjpeg-turbo-devel libtiff libwebp openjpeg2 wget yum-utils zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

NOARCH="true"
# =============================================================================
# CALLBACK: custom_test_command — Running tests
# =============================================================================
custom_test_command() {
    log_info "Running  tests..."
    tox -e $(echo py3.11-mg311 | tr -d . | sed -e 's/pypypy/pypy/')  -- "-k=test_ci_placeholder"
}
# =============================================================================
# Execute the build (invokes the python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
