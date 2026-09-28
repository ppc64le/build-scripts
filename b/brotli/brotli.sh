#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : brotli
# Version       : v1.0.9
# Source repo   : https://github.com/google/brotli
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#


# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="brotli"
PACKAGE_VERSION="${1:-v1.0.9}"
PACKAGE_URL="https://github.com/google/brotli"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building brotli C extensions
# Note: gcc/g++ are provided by the container but included for completeness
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ python3-devel python3-pip openssl-devel"
DEB_DEP_PKGS="git gcc g++ python3-dev python3-pip python3-venv libssl-dev"
SLES_DEP_PKGS="git gcc gcc-c++ python3-devel python3-pip libopenssl-devel"


pre_build() {
    log_info "installing build dependency"
    pip install pkgconfig
 }

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
