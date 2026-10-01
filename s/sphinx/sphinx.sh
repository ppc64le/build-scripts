#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : sphinx
# Version       : v8.2.3
# Source repo   : https://github.com/sphinx-doc/sphinx
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Anumala Rajesh <Anumala.Rajesh@ibm.com>
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="sphinx"
PACKAGE_VERSION="${1:-v8.2.3}"
PACKAGE_URL="https://github.com/sphinx-doc/sphinx"
NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel cargo cmake findutils git graphviz libffi libffi-devel make ncurses ncurses-devel openssl-devel python3-devel rust sqlite sqlite-devel sqlite-libs wget xz-devel zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# CALLBACK: post_clone — apply upstream coverage logging patch
# =============================================================================
post_clone() {
    log_info "Applying coverage logging patch"
    git apply "${SCRIPT_DIR}/patches/coverage-logging.patch"
}

# =============================================================================
# CALLBACK: pre_test — install test dependencies used by the upstream make test target
# =============================================================================
pre_test() {
    log_info "Installing Sphinx test dependencies"
    python -m pip install --upgrade pip setuptools wheel
    python -m pip install .[test] pytest pytest-xdist
}

# =============================================================================
# CALLBACK: custom_test_command — run the upstream make test target with the requested pytest filter
# =============================================================================
custom_test_command() {
    log_info "Running Sphinx test suite via make test"
    make test PYTHON="$(command -v python)" TEST="--junitxml=test-reports/pytest/results.xml -vv"
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
