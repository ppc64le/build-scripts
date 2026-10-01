#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : kiwisolver
# Version       : 1.5.0
# Source repo   : https://github.com/nucleic/kiwi
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="kiwi"
PACKAGE_VERSION="${1:-1.5.0}"
PACKAGE_URL="https://github.com/nucleic/kiwi"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc gcc-c++ git python3 python3-devel python3-pip wget"
DEB_DEP_PKGS="gcc g++ git python3 python3-dev python3-pip wget"
SLES_DEP_PKGS="gcc gcc-c++ git python3 python3-devel python3-pip wget"

pre_build() {
    log_info "Installing build dependencies"
    pip install "cppy" "setuptools_scm[toml]>=3.4.3"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
