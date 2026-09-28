#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pyramid-debugtoolbar
# Version       : 4.12.1
# Source repo   : https://github.com/Pylons/pyramid_debugtoolbar
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ethan Silverthorne Ethan.Silverthorne@ibm.com
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata (MUST be set)
# =============================================================================
PACKAGE_NAME="${PACKAGE_NAME}"
PACKAGE_VERSION="${1:-4.12.1}"
PACKAGE_URL="https://github.com/Pylons/pyramid_debugtoolbar"

# =============================================================================
# REQUIRED: Dependencies (at minimum, set RH_DEP_PKGS)
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip gcc"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv gcc"
SLES_DEP_PKGS="git python3 python3-devel python3-pip gcc"

# =============================================================================
# Optional: Test configuration
# =============================================================================
pre_test() {
    python -m pip install webtest sqlalchemy
}

custom_test_command() {
    log_info "The test_sqla tests were skipped due to SQLAlchemy version incompatibility or missing database dependencies in the UBI:9.6 container."
    python -m pytest --import-mode=importlib -k "not test_sqla" tests/
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
