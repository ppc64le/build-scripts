#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : graphite2
# Version       : 1.3.14
# Source repo   : https://github.com/silnrsi/graphite
# Tested on     : UBI:9.6
# Language      : Python, C, C++
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="graphite2"
PACKAGE_VERSION="${1:-1.3.14}"
PACKAGE_URL="https://github.com/silnrsi/graphite"

RH_DEP_PKGS="git gcc gcc-c++ make cmake python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_install — CMake builds the native C library; scikit-build
# then assembles the Python wheel using the compiled headers.
# =============================================================================
custom_install() {
    log_info "Installing scikit-build and fonttools"
    python -m pip install scikit-build fonttools

    log_info "Copying setup.py and Python package files to repository root"
    if [[ -d "python" ]]; then
        cp -r python/* .
    fi

    rm -rf _skbuild build dist wheelhouse

    log_info "Building binary wheel via setup.py"
    python setup.py bdist_wheel --dist-dir dist/
}

# =============================================================================
# CALLBACK: custom_test_command — no upstream Python test suite; verify the
# package can be imported from the built wheel.
# =============================================================================
custom_test_command() {
    log_info "Installing built wheel and running import smoke-test"
    python -m pip install dist/graphite2*.whl
    python -c "import graphite2; print('graphite2 imported successfully:', graphite2)"
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"
