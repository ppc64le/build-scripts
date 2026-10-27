#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : persistent
# Version       : 4.2.1
# Source repo   : https://github.com/zopefoundation/persistent
# Tested on     : rhel_7.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Archa Bhandare <barcha@us.ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="persistent"
PACKAGE_VERSION="${1:-4.2.1}"
PACKAGE_URL="https://github.com/zopefoundation/persistent"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc-c++ git python python-devel.ppc64le python-pyudev.noarch python-setuptools python-test python-virtualenv"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export DEBIAN_FRONTEND=noninteractive

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# export DEBIAN_FRONTEND=noninteractive
# sudo easy_install pip && \
#   sudo pip install --upgrade setuptools virtualenv mock ipython_genutils \
#   pytest traitlets
# git clone https://github.com/zopefoundation/persistent
# cd persistent
# sudo python setup.py install && sudo python setup.py -q test -q

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
