#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : scikit-network
# Version       : v0.33.5
# Source repo   : https://github.com/sknetwork-team/scikit-network
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="scikit-network"
PACKAGE_VERSION="${1:-v0.33.5}"
PACKAGE_URL="https://github.com/sknetwork-team/scikit-network"

# =============================================================================
# Artifact dependencies
# =============================================================================
NUMPY_ARTIFACT_VERSION="${NUMPY_ARTIFACT_VERSION:-v2.2.5}"
SCIPY_ARTIFACT_VERSION="${SCIPY_ARTIFACT_VERSION:-v1.17.1}"
BUILD_DEPS=${BUILD_DEPS:-"numpy:${NUMPY_ARTIFACT_VERSION} scipy:${SCIPY_ARTIFACT_VERSION}"}

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc-c++ make python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — install numpy/scipy artifact wheels and pinned build deps
# cython<=3.0.12 and pytest-runner are required by the package build-system
# =============================================================================
pre_build() {
    log_info "Configuring scikit-network build environment..."

    # Install NumPy and SciPy wheels from artifacts if available
    local python_abi
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")

    if [[ -n "${NUMPY_PREFIX:-}" ]]; then
        log_info "Using NumPy from artifact: ${NUMPY_PREFIX}"
        local numpy_wheel
        numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
        if [[ -n "${numpy_wheel}" ]]; then
            log_info "Installing NumPy wheel from artifact: ${numpy_wheel}"
            python -m pip install --force-reinstall --no-deps "${numpy_wheel}"
        fi
    fi

    if [[ -n "${SCIPY_PREFIX:-}" ]]; then
        log_info "Using SciPy from artifact: ${SCIPY_PREFIX}"
        local scipy_wheel
        scipy_wheel=$(find "${SCIPY_PREFIX}/wheels" -name "scipy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
        if [[ -n "${scipy_wheel}" ]]; then
            log_info "Installing SciPy wheel from artifact: ${scipy_wheel}"
            python -m pip install --force-reinstall --no-deps "${scipy_wheel}"
        fi
    fi

    log_info "Installing build dependencies: packaging, pytest-runner, cython<=3.0.12"
    python -m pip install packaging pytest-runner "cython<=3.0.12"
}

# =============================================================================
# CALLBACK: pre_test — install artifact dependencies and mirror build deps
# .venv-test is isolated from .venv-build
# =============================================================================
pre_test() {
    log_info "Setting up test environment for scikit-network..."

    # Install NumPy and SciPy wheels from artifacts if available
    local python_abi
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")

    if [[ -n "${NUMPY_PREFIX:-}" ]]; then
        local numpy_wheel
        numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
        if [[ -n "${numpy_wheel}" ]]; then
            log_info "Installing NumPy wheel from artifact into test venv: ${numpy_wheel}"
            python -m pip install --force-reinstall --no-deps "${numpy_wheel}"
        fi
    fi

    if [[ -n "${SCIPY_PREFIX:-}" ]]; then
        local scipy_wheel
        scipy_wheel=$(find "${SCIPY_PREFIX}/wheels" -name "scipy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
        if [[ -n "${scipy_wheel}" ]]; then
            log_info "Installing SciPy wheel from artifact into test venv: ${scipy_wheel}"
            python -m pip install --force-reinstall --no-deps "${scipy_wheel}"
        fi
    fi

    # Mirror build-time dependencies into test venv
    log_info "Installing mirrored build dependencies into test venv"
    python -m pip install packaging pytest-runner "cython<=3.0.12"

    # Force pip to reinstall the built wheel during the template's installation step
    # to avoid it being skipped as "already installed" due to the local source directory.
    export PIP_FORCE_REINSTALL=1
}

# =============================================================================
# CALLBACK: custom_test_command — run tests against the installed package
# =============================================================================
custom_test_command() {
    log_info "Running scikit-network tests"
    # -I isolates Python from the source tree so the installed compiled extensions are used
    # test_cliques.py / test_core.py ignored and test_metrics::test_directed deselected:
    # failures on ppc64le in the original validated script
    python -I -m pytest --pyargs sknetwork \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        --ignore-glob="*test_cliques.py" \
        --ignore-glob="*test_core.py" \
        -k "not (hierarchy and test_metrics and test_directed)"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"


