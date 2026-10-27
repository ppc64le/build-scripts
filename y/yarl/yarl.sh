#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : yarl
# Version       : v1.23.0
# Source repo   : https://github.com/aio-libs/yarl
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="yarl"
PACKAGE_VERSION="${1:-v1.23.0}"
PACKAGE_URL="https://github.com/aio-libs/yarl"

RH_DEP_PKGS="git openssl-devel bzip2-devel libffi-devel zlib-devel python3-devel python3-pip"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: pre_build — install Cython (version read from upstream
#           requirements/cython.txt at the exact tag) and build backend deps
#           so the custom pep517_backend compiles C extensions during python -m build
# =============================================================================
pre_build() {
    log_info "Installing Cython and build backend dependencies for yarl ${PACKAGE_VERSION}..."
    # yarl uses a custom PEP 517 backend (packaging/pep517_backend) that calls
    # Cython.Build.Cythonize.main() internally during build_wheel.
    # Cython must be present in the venv before python -m build --no-isolation.
    # Fetch the exact Cython pin from the upstream repo at the requested tag so
    # this script automatically stays correct for any future yarl release.
    python -m pip install -r requirements/cython.txt setuptools wheel expandvars  setuptools wheel expandvars
    # tomli is required by the custom backend on Python < 3.11
    local lang_ver=(${LANGUAGE_VERSION//./ })
    if [[ ${lang_ver[0]} -eq 3 && ${lang_ver[1]} -lt 11 ]]; then
        log_info "Python ${LANGUAGE_VERSION} — installing tomli for custom build backend"
        python -m pip install tomli
    fi
}

# =============================================================================
# CALLBACK: pre_test — install build and test dependencies in the test venv
# =============================================================================
pre_test() {
    log_info "Installing build backend dependencies in test venv..."
    python -m pip install setuptools wheel expandvars

    log_info "Installing test dependencies..."
    if [[ -f "requirements/test.txt" ]]; then
        python -m pip install -r requirements/test.txt
    fi
    python -m pip install hypothesis "pytest>=7.0"

    log_info "Removing pytest plugins that crash on entrypoint loading..."
    python -m pip uninstall -y pytest-cov pytest-xdist pytest-codspeed
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest with importlib mode so installed
#           .so extensions are found instead of the source tree
# Ignored:
#   test_quoting_benchmarks.py, test_url_benchmarks.py — require pytest-codspeed
#     which is uninstalled to prevent entrypoint import crashes
# Deselected:
#   test_url.py::test_inheritance — asserts a hardcoded class qualname that
#     includes the 'tests.' package prefix; under --import-mode=importlib the
#     module is imported as 'test_url' (no prefix), so the assertion fails with
#     a cosmetic string mismatch unrelated to package correctness
# =============================================================================
custom_test_command() {
    log_info "Running yarl tests..."
    python -I -m pytest \
        --import-mode=importlib \
        -o "addopts=" \
        --disable-warnings \
        --ignore=tests/test_quoting_benchmarks.py \
        --ignore=tests/test_url_benchmarks.py \
        --deselect tests/test_url.py::test_inheritance
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"
