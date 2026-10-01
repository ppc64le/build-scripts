#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : thinc
# Version       : release-v8.3.6
# Source repo   : https://github.com/explosion/thinc
# Tested on     : UBI:9.6
# Language      : Python, Cython
# Script License: Apache License, Version 2 or later
# Maintainer    : Puneet Sharma <Puneet.Sharma21@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - thinc is a lightweight deep learning library with Cython extensions
#   - Requires Cython, numpy, and several Explosion AI dependencies
#   - Uses GCC toolset 13 for C++ compilation
#   - Container provides: gcc-toolset-13, Python 3.12
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="thinc"
PACKAGE_VERSION="${1:-release-v8.3.6}"
PACKAGE_URL="https://github.com/explosion/thinc"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building thinc (Cython C++ extensions)
# =============================================================================
RH_DEP_PKGS="git python3 python3-pip python3-devel make gcc-toolset-13"
DEB_DEP_PKGS="git python3 python3-pip python3-dev python3-venv make g++ gcc"
SLES_DEP_PKGS="git python3 python3-pip python3-devel make gcc gcc-c++"

# =============================================================================
# CALLBACK: pre_clone
# Set up compiler environment (GCC toolset 13 on RHEL/UBI)
# =============================================================================
pre_clone() {
    # Set up GCC toolset 13 on RHEL/UBI
    if [[ -d "/opt/rh/gcc-toolset-13" ]]; then
        source /opt/rh/gcc-toolset-13/enable
        export CC=/opt/rh/gcc-toolset-13/root/usr/bin/gcc
        export CXX=/opt/rh/gcc-toolset-13/root/usr/bin/g++
        log_info "Using GCC toolset 13: $(gcc --version | head -1)"
    fi
}

# =============================================================================
# CALLBACK: pre_build
# Install build dependencies before building
# This runs INSIDE .venv-build, so pip install works correctly
# =============================================================================
pre_build() {
    log_info "Installing build dependencies..."

    # Use python3 -m pip to ensure we use the correct Python version's pip
    # Install Cython 3.x and numpy (required for setup.py)
    python3 -m pip install --no-cache-dir 'cython>=3.0,<4.0' numpy

    # Install Explosion AI dependencies required by thinc
    python3 -m pip install --no-cache-dir \
        pydantic \
        blis \
        murmurhash \
        cymem \
        preshed

    log_info "Build dependencies installed successfully"
}

# =============================================================================
# CALLBACK: custom_install
# Override the default install to ensure Cython 3.x before building
# =============================================================================
custom_install() {
    log_info "Installing thinc..."

    # Reinstall Cython 3.x (requirements.txt may have downgraded it)
    python3 -m pip install --no-cache-dir --upgrade --force-reinstall 'cython>=3.0,<4.0'

    # Build and install thinc using --no-build-isolation
    if ! python3 -m pip install --no-cache-dir --no-build-isolation . ; then
        log_error "Failed to install thinc"
        return 1
    fi

    log_info "Installation complete"
    return 0
}

# =============================================================================
# CALLBACK: custom_test_command
# Run tests if available (thinc has extensive test suite)
# =============================================================================
custom_test_command() {
    log_info "Installing test dependencies..."

    # Install test requirements
    python3 -m pip install pytest hypothesis pytest-cov

    # Install additional runtime dependencies for tests
    python3 -m pip install --no-cache-dir \
        srsly \
        wasabi \
        catalogue \
        confection \
        ml_datasets \
        packaging

    # Install type checking and linting tools
    # Install setuptools for Python 3.12+ (provides pkg_resources)
    python3 -m pip install setuptools

    # Install flake8 with version that supports Python 3.10+
    # flake8 6.0+ fixes collections.Callable issue
    python3 -m pip install mypy 'flake8>=6.0.0'

    log_info "Running test suite..."

    # Run pytest on installed package
    log_info "1. Running pytest..."
    if python3 -c "import thinc.tests" 2>/dev/null; then
        pytest --pyargs thinc.tests --disable-warnings -v || return $?
    else
        log_warn "thinc.tests module not found, skipping pytest"
        return 1
    fi

    # Run mypy type checks
    log_info "2. Running mypy type checks..."
    if command -v mypy &> /dev/null; then
        python3 -m mypy thinc || log_warn "mypy checks failed (non-critical)"
    else
        log_warn "mypy not available, skipping type checks"
    fi

    # Run flake8 linting
    log_info "3. Running flake8 linting..."
    if command -v flake8 &> /dev/null; then
        python3 -m flake8 thinc || log_warn "flake8 checks failed (non-critical)"
    else
        log_warn "flake8 not available, skipping linting"
    fi

    log_info "Test suite completed"
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"