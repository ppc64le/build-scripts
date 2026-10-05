#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : pyodbc
# Version       : 5.2.0
# Source repo   : https://github.com/mkleehammer/pyodbc
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========      platform using the mentioned version of the package.
#                 It may not work as expected with newer versions of the
#                 package and/or distribution. In such case, please
#                 contact "Maintainer" of this script.
#
# Notes:
#   - pyodbc is a C extension requiring unixODBC development headers
#   - Tests require a running ODBC-compatible database (PostgreSQL, etc.)
#     and are therefore skipped in this build script
#   - Container environment provides: gcc/g++
# -----------------------------------------------------------------------------

# Get script directory for template sourcing
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="pyodbc"
PACKAGE_VERSION="${1:-5.2.0}"
PACKAGE_URL="https://github.com/mkleehammer/pyodbc"

# =============================================================================
# REQUIRED: Dependencies
# System packages needed for building pyodbc
# Note: gcc/g++ are provided by the container
# unixODBC-devel provides the ODBC driver manager headers (sql.h, etc.)
# =============================================================================
RH_DEP_PKGS="git gcc gcc-c++ make python3-devel unixODBC-devel"
DEB_DEP_PKGS="git gcc g++ make python3-dev unixodbc-dev python3-venv"
SLES_DEP_PKGS="git gcc gcc-c++ make python3-devel unixODBC-devel"

# =============================================================================
# Skip tests - pyodbc tests require a running database
# From legacy script: "No need to run tests, as testing requires running a
# PostgreSQL container and connecting to it."
# =============================================================================
SKIP_TESTS="true"

# =============================================================================
# Source the Python template to execute the build workflow
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
