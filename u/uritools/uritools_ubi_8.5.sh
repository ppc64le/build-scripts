#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : uritools
# Version       : v3.0.0
# Source repo   : https://pypi.io/packages/source/u/uritools/uritools-3.0.0.tar.gz
# Tested on     : UBI 8.5
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Valen Mascarenhas / Vedang Wartikar <Vedang.Wartikar@ibm.com>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: uritools_ubi_8.5.sh
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="uritools"
PACKAGE_VERSION="${1:-v3.0.0}"  # PACKAGE_VERSION updated based on pypi_versions.json input file
PACKAGE_URL="https://pypi.io/packages/source/u/uritools/uritools-3.0.0.tar.gz"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="cmake gcc gcc-c++ git libffi libffi-devel make ncurses python2 python2-devel python3 python3-devel python3-pytest python38 python38-devel python39 python39-devel sqlite sqlite-devel sqlite-libs wget"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# Custom test command (extracted from original script)
custom_test_command() {
    # TODO: Review and update test commands
    if ! tox -e py36 ; then
}

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# pip3 install tox
# OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)
# wget https://pypi.io/packages/source/u/uritools/uritools-3.0.0.tar.gz
# tar -xzf uritools-3.0.0.tar.gz
# cd uritools-3.0.0
# if ! tox -e py36 ; then

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
