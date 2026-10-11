#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : tvm-ffi
# Version       : v0.1.9
# Source repo   : https://github.com/apache/tvm-ffi
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="tvm-ffi"
PACKAGE_VERSION="${1:-v0.1.9}"
PACKAGE_URL="https://github.com/apache/tvm-ffi"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make cmake ninja-build python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: custom_install — build wheel directly, bypassing the sdist step
# =============================================================================
# `python -m build --no-isolation` goes sdist→wheel; the sdist step tars the
# whole working directory including .venv-build, whose bin/python3 symlinks are
# absolute paths — rejected by Python 3.10+ tarfile data_filter (AbsoluteLinkError).
# Building with --wheel skips the sdist entirely, avoiding the problem.
custom_install() {

    log_info "Installing build backend and build-time dependencies"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install scikit-build-core cmake ninja "cython>=3.0" setuptools-scm numpy build

    log_info "Building wheel directly (--wheel skips sdist to avoid AbsoluteLinkError)"
    python -m build --no-isolation --wheel

    log_info "Installing built wheel"
    python -m pip install dist/*.whl
}

# =============================================================================
# CALLBACK: pre_test — mirror build-time deps into test venv
# =============================================================================
pre_test() {
    log_info "Installing test dependencies into test venv"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install scikit-build-core cmake ninja "cython>=3.0" setuptools-scm numpy pytest
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"