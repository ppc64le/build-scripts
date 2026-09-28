#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : dill
# Version       : dill-0.3.7
# Source repo   : https://github.com/uqfoundation/dill
# Tested on     : UBI 8.7
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="dill"
PACKAGE_VERSION="${1:-dill-0.3.7}"
PACKAGE_URL="https://github.com/uqfoundation/dill"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc gcc-c++ git python39-devel.ppc64le"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# Custom test command (extracted from original script)
custom_test_command() {
    # TODO: Review and update test commands
    python3 -m pip install coverage numpy tox
    if ! /usr/local/bin/tox -e py39 ; then
}

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# wrkdir=`pwd`
# OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
# python3 -m pip install coverage numpy tox
# if ! /usr/local/bin/tox -e py39 ; then

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
