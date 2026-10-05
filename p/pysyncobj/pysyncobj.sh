#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : PySyncObj
# Version       : v0.3.14
# Source repo   : https://github.com/bakwc/PySyncObj
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="PySyncObj"
PACKAGE_VERSION="${1:-v0.3.14}"
PACKAGE_URL="https://github.com/bakwc/PySyncObj"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test — re-install cryptography into .venv-test so HAS_CRYPTO is True during tests
# =============================================================================
pre_test() {
    log_info "Installing cryptography dependency for tests"
    python -m pip install cryptography
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"
