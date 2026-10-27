#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : simplejson
# Version       : v3.17.6
# Source repo   : https://github.com/simplejson/simplejson
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
#   - simplejson is a pure Python JSON library with optional C extension
#   - C extension (_speedups) is automatically compiled if gcc is available
#   - Falls back to pure Python if C compilation fails
#   - Container environment provides: gcc/g++
#   - Repository is pre-cloned with full history for version flexibility
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="simplejson"
PACKAGE_VERSION="${1:-v3.17.6}"
PACKAGE_URL="https://github.com/simplejson/simplejson"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building simplejson C extension
# Note: gcc/g++ are provided by the container but kept for clarity
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ python3-devel python3-pip"
DEB_DEP_PKGS="git gcc g++ python3-dev python3-pip python3-venv"
SLES_DEP_PKGS="git gcc gcc-c++ python3-devel python3-pip"

# =============================================================================
# No callbacks needed - simplejson is a simple package with:
# - Pure C extension (no Cython, no code generation)
# - Standard pytest test suite
# - No submodules or vendored dependencies
# =============================================================================

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
