#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : simsimd
# Version       : v6.5.16
# Source repo   : https://github.com/ashvardanian/NumKong
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : IBM 
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="simsimd"
PACKAGE_VERSION="${1:-v6.5.16}"
PACKAGE_URL="https://github.com/ashvardanian/NumKong"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Build dependencies (loaded automatically by python.sh from build_info.json)
# =============================================================================
BUILD_DEPS=${BUILD_DEPS:-"numpy:v2.2.5 scipy "}

# =============================================================================
# CALLBACK: pre_test — install test dependencies
# .venv-test is isolated from .venv-build; re-install numpy/scipy/ml-dtypes here too.
# =============================================================================
pre_test() {
    log_info "Installing test dependencies into test venv"
    python -m pip install --upgrade pip setuptools wheel ml_dtypes
    python -m pip install pytest pytest-repeat pytest-randomly tabulate
}

# =============================================================================
# CALLBACK: custom_test_command — run tests from the test/ directory
# Tests live in test/*.py; pyproject.toml addopts lack testpaths so pytest
# collects 0 items when run from the repo root without an explicit path.
# --import-mode=importlib with -I prevents source tree shadowing the installed .so.
# =============================================================================
custom_test_command() {
    log_info "Verifying import and running pytest"
    # v7.8.4+ renamed the Python package to 'numkong'; earlier releases used 'simsimd'
    pkg_ver=(${PACKAGE_VERSION#v})
    pkg_ver=(${pkg_ver//./ })
    if [[ ${pkg_ver[0]} -gt 7 ]] || \
       [[ ${pkg_ver[0]} -eq 7 && ${pkg_ver[1]} -gt 8 ]] || \
       [[ ${pkg_ver[0]} -eq 7 && ${pkg_ver[1]} -eq 8 && ${pkg_ver[2]} -ge 4 ]]; then
        log_info "Checking numkong import (v7.8.4+)"
        python -X faulthandler -c "import numkong; print(numkong.get_capabilities())"
        TEST_PATH="test/"
    else
        log_info "Checking simsimd import (pre-v7.8.4)"
        python -X faulthandler -c "import simsimd; print(simsimd.get_capabilities())"
        # Tests live in scripts/test.py for versions before v7.8.4
        TEST_PATH="scripts/test.py"
    fi
    python -I -m pytest "${TEST_PATH}" \
        --import-mode=importlib \
        -s -x -Wd \
        -o "addopts=" \
        --disable-warnings
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
