#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : jq
# Version       : 1.11.0
# Source repo   : https://github.com/mwilliamson/jq.py 
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Garud <Shubham.Garud@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="jq"
PACKAGE_VERSION="${1:-1.11.0}"
PACKAGE_URL="https://github.com/mwilliamson/jq.py"
NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3-devel gcc gcc-c++ cmake make autoconf libtool"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""


# =============================================================================
# CALLBACK: pre_build — install Cython so python -m build --no-isolation can compile .pyx files
# =============================================================================
pre_build() {
    log_info "Installing Cython build dependency"
    python -m pip install cython==3.2.3
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps into test venv to fix 'Cannot import setuptools.build_meta'
# =============================================================================
pre_test() {
    log_info "Installing build backend and mirrored build deps into test venv"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install cython==3.2.3
}

# =============================================================================
# Execute the build
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"