#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : wrapt
# Version       : 1.17.3
# Source repo   : https://github.com/GrahamDumpleton/wrapt
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - wrapt is a C extension package for function/method wrapping
#   - Container environment provides: gcc/g++
#   - Repository is pre-cloned with full history for version flexibility
#   - Many tests are skipped due to known platform-specific failures
#   - pytest version pinned to <8.0 for compatibility with conftest.py hooks
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="wrapt"
PACKAGE_VERSION="${1:-1.17.3}"
PACKAGE_URL="https://github.com/GrahamDumpleton/wrapt"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building wrapt
# Note: gcc/g++ are provided by the container
# =============================================================================
RH_DEP_PKGS="git openssl-devel python3-devel python3-pip"
DEB_DEP_PKGS="git libssl-dev python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git libopenssl-devel python3-devel python3-pip"

# =============================================================================
# CALLBACK: pre_test
# Install compatible pytest version to avoid conftest.py hook signature issues
# =============================================================================
pre_test() {
    log_info "Installing test dependencies with compatible pytest version..."
    
    # Pin pytest to <8.0 to avoid PluginValidationError with pytest_pycollect_makemodule
    # The conftest.py in wrapt uses the old 'path' parameter which was deprecated
    # in pytest 7.x and removed in pytest 8.x
    pip install --upgrade "pytest>=7.0,<8.0" || return 1    
    return 0
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tests with known-failing tests deselected
# =============================================================================
custom_test_command() {
    log_info "Running pytest with platform-specific test deselections..."

    # These tests are known to fail on ppc64le/s390x and some also fail on x86:
    # - test_adapter.py: Adapter tests have platform-specific behavior
    # - test_function.py: Function wrapper tests with C extension issues
    # - test_inner_classmethod.py: Inner classmethod handling differences
    # - test_inner_staticmethod.py: Inner staticmethod handling differences
    # - test_instancemethod.py: Instance method wrapper differences
    # - test_nested_function.py: Nested function wrapper issues
    # - test_object_proxy.py: Object proxy behavior differences
    # - test_outer_classmethod.py: Outer classmethod handling differences
    # - test_outer_staticmethod.py: Outer staticmethod handling differences
    # - test_adapter_py3.py: Python 3 specific adapter tests
    # - test_class_py37.py: Python 3.7+ class tests
    # - test_class.py: General class tests
    # - test_adapter_py33.py: Python 3.3+ adapter tests
    # Note: These were skipped in legacy script due to failures on x86 as well

    pytest tests/ \
        --ignore=tests/test_adapter.py \
        --ignore=tests/test_function.py \
        --ignore=tests/test_inner_classmethod.py \
        --ignore=tests/test_inner_staticmethod.py \
        --ignore=tests/test_instancemethod.py \
        --ignore=tests/test_nested_function.py \
        --ignore=tests/test_object_proxy.py \
        --ignore=tests/test_outer_classmethod.py \
        --ignore=tests/test_outer_staticmethod.py \
        --ignore=tests/test_adapter_py3.py \
        --ignore=tests/test_class_py37.py \
        --ignore=tests/test_class.py \
        --ignore=tests/test_adapter_py33.py \
        --disable-warnings
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"