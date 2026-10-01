#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : sniffio
# Version       : v1.3.1
# Source repo   : https://github.com/python-trio/sniffio
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="sniffio"
PACKAGE_VERSION="${1:-v1.3.1}"
PACKAGE_URL="https://github.com/python-trio/sniffio"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel"
DEB_DEP_PKGS="git python3 python3-dev python3-venv"
SLES_DEP_PKGS=""

# Package is pure Python, so skip architecture-specific compilation.
NOARCH="true"

# =============================================================================
# CALLBACK: pre_build
# Install build backend requirements before invoking the template build.
# =============================================================================
pre_build() {
    log_info "Installing build dependencies"
    python -m pip install "setuptools_scm>=6.4"
}

# =============================================================================
# CALLBACK: pre_test - Install test dependencies
# =============================================================================
pre_test() {
    log_info "Installing test dependencies"
    python -m pip install pytest-timeout dirty_equals curio
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"
