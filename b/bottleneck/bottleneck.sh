#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : bottleneck
# Version       : v1.6.0
# Source repo   : https://github.com/pydata/bottleneck
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivansh Sharma <shivansh.s1@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="bottleneck"
PACKAGE_VERSION="${1:-v1.6.0}"
PACKAGE_URL="https://github.com/pydata/bottleneck"

# =============================================================================
# Artifact dependencies
# Bottleneck 1.3.x must use the NumPy 1.x artifact; newer releases use NumPy 2.x.
# =============================================================================
pkg_ver=(${PACKAGE_VERSION#v})
pkg_ver=(${pkg_ver//./ })
if [[ ${pkg_ver[0]} -eq 1 && ${pkg_ver[1]} -le 3 ]]; then
    NUMPY_ARTIFACT_VERSION="${NUMPY_ARTIFACT_VERSION:-v1.26.4}"
else
    NUMPY_ARTIFACT_VERSION="${NUMPY_ARTIFACT_VERSION:-v2.2.5}"
fi
BUILD_DEPS=${BUILD_DEPS:-"numpy:${NUMPY_ARTIFACT_VERSION}"}
unset pkg_ver

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building bottleneck
# Note: gcc/g++ are provided by the container, but -devel packages needed
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ python3-devel python3-pip openssl-devel"
DEB_DEP_PKGS="git gcc g++ python3-dev python3-pip python3-venv libssl-dev"
SLES_DEP_PKGS="git gcc gcc-c++ python3-devel python3-pip libopenssl-devel"

# =============================================================================
# CALLBACK: pre_build
# Validate NumPy supplied through BUILD_DEPS and install the remaining tooling.
# =============================================================================
pre_build() {
    log_info "Verifying NumPy artifact is present"
    [[ -n "${NUMPY_PREFIX:-}" && -d "${NUMPY_PREFIX}" ]]

    log_info "Using NumPy artifact ${NUMPY_ARTIFACT_VERSION} from ${NUMPY_PREFIX}"
    python -c "import numpy; print('NumPy artifact:', numpy.__version__, numpy.__file__)"

    log_info "Installing Bottleneck build tooling"
    python -m pip install versioneer
}

# =============================================================================
# CALLBACK: pre_test — set up test environment dependencies and verify NumPy
# =============================================================================
pre_test() {
    log_info "Installing build backend and tooling in test venv"
    python -m pip install --upgrade pip setuptools wheel versioneer

    log_info "Verifying NumPy from artifact in the test environment"
    python -c "import numpy; print('NumPy artifact:', numpy.__version__, numpy.__file__)"
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest against bottleneck tests
# =============================================================================
custom_test_command() {
    log_info "Running pytest against bottleneck tests"
    python -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        bottleneck/tests
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
