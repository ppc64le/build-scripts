#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : murmurhash
# Version       : release-v1.0.15
# Source repo   : https://github.com/explosion/murmurhash
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="murmurhash"
PACKAGE_VERSION="${1:-release-v1.0.15}"
PACKAGE_URL="https://github.com/explosion/murmurhash"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ python3-devel make"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — install Cython build dependency required by murmurhash
#   murmurhash uses Cython-generated C++ bindings; Cython must be present in
#   the build venv before python -m build --no-isolation runs.
# =============================================================================
pre_build() {
    log_info "Installing Cython and build backend dependencies for ${PACKAGE_NAME} ${PACKAGE_VERSION}"
    python -m pip install cython
}

# =============================================================================
# CALLBACK: pre_test — mirror build deps into test venv
#   .venv-test is isolated from .venv-build; setuptools/wheel/cython must be
#   reinstalled here so pytest can import the compiled extension correctly.
# =============================================================================
pre_test() {
    log_info "Installing build backend and test dependencies for ${PACKAGE_NAME} ${PACKAGE_VERSION}"
    python -m pip install cython
}

# =============================================================================
# CALLBACK: custom_test_command — use -I (isolated mode) to prevent Python from
#   adding the clone directory to sys.path, which would shadow the installed
#   package and cause: "ModuleNotFoundError: No module named 'murmurhash.mrmr'"
# =============================================================================
custom_test_command() {
    log_info "Running ${PACKAGE_NAME} tests"
    python -I -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        --pyargs murmurhash
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
