#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : nbconvert
# Version       : v7.16.4
# Source repo   : https://github.com/jupyter/nbconvert
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2.0 or later
# Maintainer    : Anumala Rajesh <Anumala.Rajesh@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="nbconvert"
PACKAGE_VERSION="${1:-v7.16.4}"
PACKAGE_URL="https://github.com/jupyter/nbconvert"


NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git wget pandoc"
DEB_DEP_PKGS=""   
SLES_DEP_PKGS="" 

# =============================================================================
# CALLBACK: pre_test — Install test dependencies before running tests
# =============================================================================
pre_test() {
    log_info "Installing test dependencies"
    python -m pip install "nbconvert[test]" "mistune>=2.0.3,<3.1.0"
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"
