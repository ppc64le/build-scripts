#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : py-filelock
# Version       : n/a
# Source repo   : https://github.com/benediktschmitt/py-filelock
# Tested on     : ubuntu_16.04
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Snehlata Mohite <smohite@us.ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="py-filelock"
PACKAGE_VERSION="${1:-n/a}"
PACKAGE_URL="https://github.com/benediktschmitt/py-filelock"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS=""
DEB_DEP_PKGS="build-essential git python python-dev python-lxml python-pip python-virtualenv"
SLES_DEP_PKGS=""

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# sudo pip install --upgrade pip
# git clone https://github.com/benediktschmitt/py-filelock
# virtualenv -p python2 --system-site-packages env2
# cd py-filelock
# python setup.py install
# python test.py
# rm -rf py-filelock

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
