#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : gmpy2
# Version       : gmpy2-2.1.2
# Source repo   : https://github.com/gmpy2/gmpy2
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="gmpy2"
PACKAGE_VERSION="${1:-gmpy2-2.1.2}"
PACKAGE_URL="https://github.com/gmpy2/gmpy2"


# =============================================================================
# REQUIRED: Dependencies
# GMP, MPFR, and MPC are required for multi-precision arithmetic support
# Note: gcc/g++/make are provided by the container
# =============================================================================
RH_DEP_PKGS="git gmp-devel mpfr-devel libmpc-devel openssl-devel python3-devel python3-pip"
DEB_DEP_PKGS="git libgmp-dev libmpfr-dev libmpc-dev libssl-dev python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git gmp-devel mpfr-devel mpc-devel libopenssl-devel python3-devel python3-pip"

# Override the template default (setuptools<70) - gmpy2 requires setuptools>=77,<80
SETUPTOOLS_VERSION="<80,>=77"

# =============================================================================
# CALLBACK: pre_build
# Install cython before the build - gmpy2 uses Cython extensions
# Note: This runs INSIDE .venv-build, so pip install works correctly
# =============================================================================
pre_build() {
    log_info "Installing cython for gmpy2 extension compilation..."
    pip install "setuptools_scm[toml]>=6.0" cython
}

# =============================================================================
# CALLBACK: custom_test_command
# gmpy2 uses its own test runner (test_cython/runtests.py), not pytest
# =============================================================================
custom_test_command() {
    log_info "Running gmpy2 test suite..."

    # gmpy2 uses a custom test runner script
    if [[ -f "test_cython/runtests.py" ]]; then
        python test_cython/runtests.py
    elif [[ -f "test/runtests.py" ]]; then
        python test/runtests.py
    else
        # Fallback: try running the test module directly
        log_info "No runtests.py found, attempting pytest..."
        pytest -v || python -m pytest -v
    fi
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
