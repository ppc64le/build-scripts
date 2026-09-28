#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : itsdangerous
# Version       : 2.1.2
# Source repo   : https://github.com/pallets/itsdangerous
# Tested on     : UBI: 8.7
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="itsdangerous"
PACKAGE_VERSION="${1:-2.1.2}"
PACKAGE_URL="https://github.com/pallets/itsdangerous"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc-c++ git python3 python3-setuptools python3-test python3-virtualenv python39-devel.ppc64le"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export PACKAGE_VERSION=${1:-"2.1.2"}
export PACKAGE_NAME=itsdangerous
export PACKAGE_URL=https://github.com/pallets/itsdangerous
export TOXENV=py39

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# export PACKAGE_VERSION=${1:-"2.1.2"}
# export PACKAGE_NAME=itsdangerous
# export PACKAGE_URL=https://github.com/pallets/itsdangerous
# pip3 install --upgrade setuptools virtualenv mock ipython_genutils pytest traitlets
# export TOXENV=py39
# virtualenv -p python3 --system-site-packages env2
# /bin/bash -c "source env2/bin/activate"
# pip3 install tox
# PATH=$PATH:/usr/local/bin/
# if !(python3 setup.py install) ; then
# if !(tox); then

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
