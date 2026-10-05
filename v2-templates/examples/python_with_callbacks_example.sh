#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : some-complex-package
# Version       : v2.0.0
# Source repo   : https://github.com/example/some-complex-package
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Your Name <your.email@example.com>
#
# This is a COMPLEX example demonstrating callback hooks.
# Define functions before sourcing the template to customize behavior.
# -----------------------------------------------------------------------------

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="${PACKAGE_NAME}"
PACKAGE_VERSION="${1:-PACKAGE_VERSION}"
PACKAGE_URL="${PACKAGE_URL}"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip gcc gcc-c++ openssl-devel"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv gcc g++ libssl-dev"
SLES_DEP_PKGS="git python3 python3-devel python3-pip gcc gcc-c++ libopenssl-devel"

# =============================================================================
# OPTIONAL: Callback functions
# Define these BEFORE sourcing the template
# =============================================================================

# Called before cloning - use for extra system setup
pre_clone() {
    log_info "Setting up extra build environment..."
    export CFLAGS="-O2"
    export LDFLAGS="-L/usr/local/lib"
}

# Called after checkout - use for patches and source modifications
post_clone() {
    log_info "Applying patches..."

    # Example: Apply a patch file
    # git apply "${SCRIPT_DIR}/patches/fix-build.patch"

    # Example: Inline fix using sed
    # sed -i 's/old_api_call/new_api_call/g' src/module.py

    # Example: Modify setup.py for compatibility
    # echo "install_requires.append('backports.functools')" >> setup.py

    log_info "Patches applied successfully"
}

# Called before pip install - extra environment or dependencies
pre_build() {
    log_info "Installing extra build dependencies..."
    pip install cython numpy
}

# Called after build, before tests - verification
post_build() {
    log_info "Verifying installation..."
    python -c "import some_complex_package; print(some_complex_package.__version__)"
}

# Override default test behavior
custom_test_command() {
    log_info "Running custom test suite..."

    # Example: Run specific test file with timeout
    python -m pytest tests/unit/ -x --timeout=300 -v

    # Example: Skip slow integration tests in CI
    # python -m pytest tests/ --ignore=tests/integration/
}

# Called after tests pass - cleanup or artifact collection
post_test() {
    log_info "Collecting test artifacts..."
    # cp -r .coverage "${SCRIPT_DIR}/coverage/"
}

# =============================================================================
# Execute the build (sources the template which runs the workflow)
# =============================================================================
source "${SCRIPT_DIR}/../python.sh"
