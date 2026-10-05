#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pyramid_jinja2
# Version       : 2.10.1
# Source repo   : https://github.com/Pylons/pyramid_jinja2
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pyramid_jinja2"
PACKAGE_VERSION="${1:-2.10.1}"
PACKAGE_URL="https://github.com/Pylons/pyramid_jinja2"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test — install test-only runtime deps
# =============================================================================
pre_test() {
    log_info "Installing test runtime dependency: webtest"
    python -m pip install webtest
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

