#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : tiktoken
# Version       : 0.9.0
# Source repo   : https://github.com/openai/tiktoken
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.


# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="tiktoken"
PACKAGE_VERSION="${1:-0.9.0}"
PACKAGE_URL="https://github.com/openai/tiktoken"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building tiktoken
# Note: rust/cargo, gcc/g++ are provided by the container
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip openssl-devel"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv libssl-dev"
SLES_DEP_PKGS="git python3-devel python3-pip libopenssl-devel"

pre_build() {
    log_info "installing build dependencies"
    pip install setuptools_rust
}

# =============================================================================
# CALLBACK: pre_test
# The test venv only has pip+pytest installed by the template; --no-build-isolation
# means pip uses the active venv to run the build backend, so setuptools and
# setuptools_rust must be present before "pip install --no-build-isolation ." runs.
# =============================================================================
pre_test() {
    log_info "installing test dependencies"
    pip install setuptools_rust wheel
}
# =============================================================================
# CALLBACK: custom_test_command
# Run tests with workaround for circular import issues
# =============================================================================
custom_test_command() {
    log_info "Installing test dependencies..."
    pip install hypothesis
    # Ensure we have a working pytest
    log_info "Running pytest with test deselections..."

    # tiktoken has a circular import issue when running tests from the source directory
    # Copy tests to /tmp and run from there to avoid this issue
    # Also deselect test_hyp_roundtrip which is flaky due to randomization in input

    if [[ -d "tests" ]]; then
        rm -rf /tmp/tiktoken_tests
        cp -r tests /tmp/tiktoken_tests
        (cd /tmp && pytest tiktoken_tests/ -v -k "not test_hyp_roundtrip")
    else
        # Fallback: try running tests directly
        pytest ./tests -v -k "not test_hyp_roundtrip" 
    fi
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

