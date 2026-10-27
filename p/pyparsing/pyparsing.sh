#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pyparsing
# Version       : 3.2.3
# Source repo   : https://github.com/pyparsing/pyparsing.git
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pyparsing"
PACKAGE_VERSION="${1:-3.2.3}"
PACKAGE_URL="https://github.com/pyparsing/pyparsing"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel gcc-toolset-13 git libffi-devel libjpeg-devel make openssl-devel python3 python3-devel python3-pip wget zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH=true


pre_test(){
    log_info "Installing missing test dependencies (railroad-diagrams, Jinja2) required because the test cases are failing due to missing modules."
    pip install railroad-diagrams Jinja2
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

