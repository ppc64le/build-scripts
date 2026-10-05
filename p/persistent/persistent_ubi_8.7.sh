#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : persistent
# Version       : 5.1
# Source repo   : https://github.com/zopefoundation/persistent
# Tested on     : UBI 8.7
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Garud <Shubham.Garud@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="persistent"
PACKAGE_VERSION="${1:-5.1}"
PACKAGE_URL="https://github.com/zopefoundation/persistent"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc gcc-c++ git make python39 python39-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# Custom test command (extracted from original script)
custom_test_command() {
    # TODO: Review and update test commands
    if ! tox -e py39 ; then
}

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# pip3 install pytest tox
# PATH=$PATH:/usr/local/bin/
# REQUIREMENTS_PRESENT=(`find . -print | grep -i requirements.txt`)
# for i in "${REQUIREMENTS_PRESENT[@]}"; do
#         echo "Installing using pip from file:"
#         echo $i
#         pip3  install -r $i
# if [ -f "setup.py" ];then
#         echo "setup.py file exists"
#         echo "setup.py not present"
# if [ -f "tox.ini" ];then
#         echo "tox.ini file exists"
#         if ! tox -e py39 ; then
#         echo "tox.ini not present"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
