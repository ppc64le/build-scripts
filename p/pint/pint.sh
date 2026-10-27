#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pint
# Version       : 0.24.4
# Source repo   : https://github.com/hgrecco/pint
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Ramnath Nayak <Ramnath.Nayak@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pint"
PACKAGE_VERSION="${1:-0.24.4}"
PACKAGE_URL="https://github.com/hgrecco/pint"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ git make python3 python3-devel python3-pip wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Mark as pure Python package
# =============================================================================
NOARCH="true"

# =============================================================================
# The pint/testsuite/benchmarks directory is excluded because it contains performance profiling tests (using tools like pytest-benchmark or asv) that measure execution speed rather than validate correctness. 
# These benchmarks are intended to be run in controlled, dedicated environments for regression tracking and are not part of the standard functional test suite.
# =============================================================================
custom_test_command() {
    log_info "Installing test dependencies.."
    python -m pip install pytest pytest-subtests pytest-xdist
    python -m pytest -v --ignore=pint/testsuite/benchmarks
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
