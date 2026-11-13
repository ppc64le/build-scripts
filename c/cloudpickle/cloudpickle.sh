#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : cloudpickle
# Version       : v3.1.1
# Source repo   : https://github.com/cloudpipe/cloudpickle
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="cloudpickle"
PACKAGE_VERSION="${1:-v3.1.1}"
PACKAGE_URL="https://github.com/cloudpipe/cloudpickle"
NOARCH="true"

# =============================================================================
# Artifact dependencies and declaration
# =============================================================================
NUMPY_ARTIFACT_VERSION="${NUMPY_ARTIFACT_VERSION:-v2.2.5}"
BUILD_DEPS=${BUILD_DEPS:-"numpy:${NUMPY_ARTIFACT_VERSION}"}

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_test — pin flit_core<4 to support [tool.flit.metadata] in pyproject.toml
# v3.1.1 and v3.1.2 use [tool.flit.metadata] which requires flit_core<4;
# an unpinned "flit_core" in build-system.requires resolves to >=4 which
# rejects this legacy table format with a ConfigError.
# Also installs NumPy from the artifact (not PyPI) into the isolated test venv.
# =============================================================================
pre_test() {
    log_info "Pinning flit_core<4 to support legacy [tool.flit.metadata] format"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install "flit_core<4"

    if [[ -z "${NUMPY_PREFIX:-}" || ! -d "${NUMPY_PREFIX}" ]]; then
        log_error "NumPy artifact is required but NUMPY_PREFIX is invalid: ${NUMPY_PREFIX:-<unset>}"
        log_error "Expected build order: numpy:${NUMPY_ARTIFACT_VERSION} -> cloudpickle:${PACKAGE_VERSION}"
        false
    fi
    log_info "Using NumPy from artifact: ${NUMPY_PREFIX}"

    # Prefer the artifact wheel matching the active Python ABI (cp310, cp311, ...)
    # because NumPy contains compiled extensions that are not portable across minors.
    local python_abi numpy_wheel
    python_abi=$(python -c "import sys; print(f'cp{sys.version_info.major}{sys.version_info.minor}')")
    log_info "Looking for NumPy artifact wheel matching Python ABI ${python_abi}"
    numpy_wheel=$(find "${NUMPY_PREFIX}/wheels" -name "numpy-*-${python_abi}-${python_abi}-*.whl" -print 2>/dev/null | head -1)
    if [[ -n "${numpy_wheel}" ]]; then
        log_info "Installing NumPy wheel from artifact into test venv: ${numpy_wheel}"
        python -m pip install --force-reinstall --no-deps "${numpy_wheel}"
    else
        log_warn "NumPy ${python_abi} wheel not found under ${NUMPY_PREFIX}/wheels; using artifact PYTHONPATH"
        log_info "Verifying NumPy is importable from the sourced artifact environment"
        python -c "import numpy; print('NumPy version:', numpy.__version__)"
    fi

    log_info "Installing test dependencies"
    python -m pip install pytest-cov psutil tornado
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest directly, bypassing tox
# tox rebuilds the package sdist via flit_core and hits the same ConfigError;
# NOARCH=true already installs cloudpickle from PyPI so no sdist rebuild is needed.
# =============================================================================
custom_test_command() {
    log_info "Running pytest directly (bypassing tox to avoid flit_core sdist rebuild)"
    python -m pip uninstall -y pytest-cov 2>/dev/null
    # Pass -s (no capture) so pytest does not wrap sys.stdout/stderr in EncodedFile;
    # without it cloudpickle cannot pickle the captured stream wrappers.
    # tox.ini already sets addopts = -s; we mirror that here since we bypass tox.
    python -m pytest tests/ \
        -o "addopts=" \
        --disable-warnings \
        -s \
        -v
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
