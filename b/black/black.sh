#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : black
# Version       : 26.5.1
# Source repo   : https://github.com/psf/black
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="black"
PACKAGE_VERSION="${1:-26.5.1}"
PACKAGE_URL="https://github.com/psf/black"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel gcc gcc-c++ git libffi-devel make openssl-devel python-devel python-pip wget zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""
NOARCH="true"

# =============================================================================
# CALLBACK: pre_test — Install test dependencies before running tests
# =============================================================================
pre_test() {
    log_info "Installing dependencies for tests"
    python -m pip install -r test_requirements.txt
    python -m pip install "black[d]" "pathspec<0.12" "click>=8.0.0,<8.2.0"
}

# =============================================================================
# CALLBACK: custom_test_command — run pytest directly so the template does not fall back to tox
# tox rebuilds its own env from test_requirements.txt (pytest-xdist<3.0.2) and fails with
# "No module named 'py.log'; 'py' is not a package" when run with --numprocesses auto.
# =============================================================================
custom_test_command() {
    log_info "Running tests (no_jupyter set, same as tox.ini; without xdist/coverage)"
    # pyproject.toml sets filterwarnings = ["error"]; black 22.12.0 uses ast.Str, which emits
    # "DeprecationWarning: ast.Str is deprecated" on Python 3.12+, turning every format test into
    # a failure. -W overrides the ini filter so the deprecation is not raised as an error.
    python -m pytest tests \
        --run-optional no_jupyter \
        -o "addopts=" \
        -W "ignore::DeprecationWarning" \
        --disable-warnings
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
