#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : terminado
# Version       : 0.18.1
# Source repo   : https://github.com/takluyver/terminado
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="terminado"
PACKAGE_VERSION="${1:-0.18.1}"
PACKAGE_URL="https://github.com/takluyver/terminado"

NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test — install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing test dependencies"
    python -m pip install pytest-timeout
}

# =============================================================================
# CALLBACK: custom_test_command — suppress ResourceWarning from tornado teardown
# =============================================================================
custom_test_command() {
    log_info "Running tests"
    python -m pytest -p no:warnings tests/
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

