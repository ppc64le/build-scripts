#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : rq
# Version       : v2.3.2
# Source repo   : https://github.com/nvie/rq
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="rq"
PACKAGE_VERSION="${1:-v2.3.2}"
PACKAGE_URL="https://github.com/nvie/rq"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"

# =============================================================================
# CALLBACK: custom_test_command — smoke-test only; full test suite requires a
#           live Redis server on localhost:6379 which is not available in CI
# =============================================================================
custom_test_command() {
    log_info "Running rq import smoke-test"
    python -c "import rq; print('rq version:', rq.VERSION)"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

