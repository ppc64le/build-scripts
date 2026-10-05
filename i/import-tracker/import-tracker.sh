#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : import-tracker
# Version       : 3.2.1
# Source repo   : https://github.com/IBM/import-tracker
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="import-tracker"
PACKAGE_VERSION="${1:-3.2.1}"
PACKAGE_URL="https://github.com/IBM/import-tracker"
NOARCH="true"
# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="make autoconf automake cmake libffi-devel openssl-devel openblas-devel sqlite-devel zlib-devel bzip2-devel libtool pkgconf-pkg-config fontconfig-devel python3-devel cargo"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""


# =============================================================================
# CALLBACK: pre_test — set release version and install package-specific test dependencies
# =============================================================================
pre_test() {
    log_info "Setting RELEASE_VERSION for tests"
    export RELEASE_VERSION="${PACKAGE_VERSION}"
    log_info "Installing package-specific test dependencies"
    python -m pip install -r requirements_test.txt "alchemy-logging==1.0.3" "alog==1.0.0" PyYAML
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

