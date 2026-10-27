#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : flatbuffers
# Version       : v2.0.0
# Source repo   : https://github.com/google/flatbuffers
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="flatbuffers"
PACKAGE_VERSION="${1:-v2.0.0}"
PACKAGE_URL="https://github.com/google/flatbuffers"
NOARCH="true"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran git make openssl-devel python3-devel python3-pip wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Callback : pre_test
# installing required dependencies
# =============================================================================
pre_test() {
    log_info "using pre_test hook"
    python -m pip install "numpy<2"

    # Build flatc compiler from source
    log_info "Building flatc compiler..."
    cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DFLATBUFFERS_BUILD_TESTS=OFF -DFLATBUFFERS_STRICT_MODE=OFF -DFLATBUFFERS_CXX_FLAGS="-Wno-error" .
    make -j$(nproc) flatc
}

# =============================================================================
# Callback : custom_test_command
# running test cases for flatbuffers
# =============================================================================
custom_test_command() {
    log_info "using custom_test_command hook"
    # Run the official test runner script directly, which compiles the schemas and runs the tests
    ./tests/PythonTest.sh
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
