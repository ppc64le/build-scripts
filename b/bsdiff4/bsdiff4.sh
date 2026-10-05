#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : bsdiff4
# Version       : 1.2.6
# Source repo   : https://github.com/ilanschnell/bsdiff4
# Tested on     : UBI:9.6
# Language      : Python (C extension)
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - bsdiff4 is a Python wrapper for bsdiff/bspatch (binary diff/patch)
#   - Contains C extension for performance
#   - Container environment provides: gcc/g++
#   - Repository is pre-cloned with full history for version flexibility
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="bsdiff4"
PACKAGE_VERSION="${1:-1.2.6}"
PACKAGE_URL="https://github.com/ilanschnell/bsdiff4"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building bsdiff4
# Note: gcc/g++ are provided by the container but we need -devel packages
# =============================================================================
RH_DEP_PKGS="git python3-devel python3-pip bzip2-devel"
DEB_DEP_PKGS="git python3-dev python3-pip python3-venv libbz2-dev"
SLES_DEP_PKGS="git python3-devel python3-pip libbz2-devel"

custom_test_command() {
    log_info "Testing the built wheel artifact..."
    # Use isolated Python mode and --pyargs so pytest resolves the installed
    # wheel instead of importing from the source checkout.
    python -I -m pytest --pyargs bsdiff4 -o "addopts="
}

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
