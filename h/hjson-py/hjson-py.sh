#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : hjson-py
# Version       : v3.0.2
# Source repo   : https://github.com/hjson/hjson-py.git
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="hjson-py"
PACKAGE_VERSION="${1:-v3.0.2}"
PACKAGE_URL="https://github.com/hjson/hjson-py"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="bzip2-devel gcc gcc-c++ git libffi-devel make openssl-devel python3-devel python3-pip wget zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# Test configuration
# =============================================================================
custom_test_command() {
    log_info "The two tests are skipped because they test stdin/stdout piping behavior of the hjson command-line tool, which fails in the headless/non-interactive CI environment where stdin is not a TTY."
    python -m pytest --deselect=hjson/tests/test_tool.py::TestTool::test_infile_stdout --deselect=hjson/tests/test_tool.py::TestTool::test_stdin_stdout
}

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
