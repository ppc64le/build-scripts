#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : msgspec
# Version       : 0.19.0
# Source repo   : https://github.com/jcrist/msgspec
# Tested on     : UBI:9.6
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - msgspec has C extensions (no Cython) - requires gcc and python-devel
#   - No submodules or code generation required
#   - Container environment provides: gcc/g++
#   - Repository is pre-cloned with full history for version flexibility
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="msgspec"
PACKAGE_VERSION="${1:-0.19.0}"
PACKAGE_URL="https://github.com/jcrist/msgspec"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building msgspec
# Note: gcc/g++ are provided by the container
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git python3-devel python3-pip"

# =============================================================================
# CALLBACK: pre_test
# =============================================================================
pre_test() {
    log_info "running pre test hook"
    python -m pip install attrs PyYAML tomli_w
}

# =============================================================================
# CALLBACK: custom_test_command
# Use -I flag to prevent importing from source directory (C extensions)
# Skip test_raw_copy_doesnt_leak: memory profiling test that spawns subprocess
# without -I flag, causing import failure (not a functional issue)
# =============================================================================
custom_test_command() {
    log_info "running custom test hook"
    python -I -m pytest \
        -o "addopts=" \
        --deselect=tests/test_raw.py::test_raw_copy_doesnt_leak \
        -v
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
