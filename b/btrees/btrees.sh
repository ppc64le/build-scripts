#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : BTrees
# Version       : 6.1
# Source repo   : https://github.com/zopefoundation/BTrees
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PACKAGE_NAME="BTrees"
PACKAGE_VERSION="${1:-6.1}"
PACKAGE_URL="https://github.com/zopefoundation/BTrees"

RH_DEP_PKGS="git python3-devel python3-pip zlib-devel"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv zlib1g-dev"
SLES_DEP_PKGS="git python3-devel python3-pip zlib-devel"

# =============================================================================
# CALLBACK: pre_build — install C extension build dependencies (persistent, cffi)
# =============================================================================
pre_build() {
    log_info "Installing build dependencies for BTrees C extensions..."
    python -m pip install persistent cffi
}

# =============================================================================
# CALLBACK: pre_test — install test dependencies for BTrees
# =============================================================================
pre_test() {
    log_info "Installing test dependencies (persistent, cffi, zope.testrunner)"
    python -m pip install persistent cffi ".[test]" transaction "zope.testrunner>=6.4"
}

# =============================================================================
# CALLBACK: custom_test_command — run tests with zope-testrunner
# =============================================================================
custom_test_command() {
    # BTrees uses zope-testrunner for testing
    log_info "Running BTrees tests with zope-testrunner"
    zope-testrunner --test-path=src -vc
}

source "${SCRIPT_DIR}/../../v2-templates/python.sh"
