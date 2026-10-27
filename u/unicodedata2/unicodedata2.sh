#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : unicodedata2
# Version       : 16.0.0
# Source repo   : https://github.com/fonttools/unicodedata2
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : ICH <ich@us.ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - unicodedata2 is a C extension backporting Python's unicodedata module
#   - Package is 98% C code with minimal Python wrapper
#   - No external runtime dependencies, only build-time compilation needed
#   - Tests run from the tests/ subdirectory using pytest
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="unicodedata2"
PACKAGE_VERSION="${1:-16.0.0}"
PACKAGE_URL="https://github.com/fonttools/unicodedata2"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building unicodedata2 C extension
# Note: gcc/g++ are provided by the container but included for completeness
# =============================================================================
RH_DEP_PKGS="git python3 python3-devel python3-pip gcc gcc-c++"
DEB_DEP_PKGS="git python3 python3-dev python3-pip python3-venv gcc g++"
SLES_DEP_PKGS="git python3 python3-devel python3-pip gcc gcc-c++"


# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"

