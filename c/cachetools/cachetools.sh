#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : cachetools
# Version       : v6.2.1
# Source repo   : https://github.com/tkem/cachetools
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Pranith Rao <Pranith.Rao@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cachetools"
PACKAGE_VERSION="${1:-v6.2.1}"
PACKAGE_URL="https://github.com/tkem/cachetools"
NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Ensure setuptools is available in the test venv before
# installing from local source with --no-build-isolation
# =============================================================================
pre_test() {
    log_info "Installing setuptools"
    pip install --upgrade setuptools
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
