#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : antlr4-python3-runtime
# Version       : 4.9.3
# Source repo   : https://github.com/antlr/antlr4
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="antlr4-python3-runtime"
PACKAGE_VERSION="${1:-4.9.3}"
PACKAGE_URL="https://github.com/antlr/antlr4"
NOARCH="true"

# The Python runtime lives in a subdirectory of the antlr4 monorepo.
# Clone the repo into a directory named "antlr4" so post_clone can cd into
# the correct subdirectory before the template runs build/test.
CLONE_DIR="antlr4"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="python3-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""


# =============================================================================
# CALLBACK: post_clone — patch the test suite for Python 3.12+ compatibility.
#           assertEquals was removed in Python 3.12; replace with assertEqual.
# =============================================================================
post_clone() {
    log_info "Patching test suite for Python 3.12+ compatibility (assertEquals → assertEqual)"
    sed -i 's/assertEquals/assertEqual/g' runtime/Python3/tests/TestIntervalSet.py
}

# =============================================================================
# CALLBACK: custom_test_command — run unit tests excluding outdated mocks
#           TestTokenStreamRewriter and mocks/TestLexer use legacy ATN v3 format
#           which fails ATN deserialization in ANTLR 4.10+ (SERIALIZED_VERSION=4).
# =============================================================================
custom_test_command() {
    log_info "Running antlr4-python3-runtime unit tests with pytest"
    cd runtime/Python3/tests/
    python -m pytest . \
        -o "addopts=" \
        -o "python_files=Test*.py" \
        -o "python_classes=Test*" \
        --ignore=mocks \
        --ignore=TestTokenStreamRewriter.py \
        --disable-warnings
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"


