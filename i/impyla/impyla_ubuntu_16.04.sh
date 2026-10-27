#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : impyla
# Version       : v0.14.0
# Source repo   : https://github.com/cloudera/impyla.git
# Tested on     : ubuntu_16.04 (python27)
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Snehlata Mohite <smohite@us.ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="impyla"
PACKAGE_VERSION="${1:-v0.14.0}"
PACKAGE_URL="https://github.com/cloudera/impyla.git"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS=""
DEB_DEP_PKGS="build-essential gcc git libsasl2-dev libxml2 libxml2-dev make python python-bitarray python-dev python-libxml2 python-setuptools"
SLES_DEP_PKGS=""

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# sudo easy_install pip
# sudo pip install --upgrade pip
# sudo pip install six thrift thriftpy thrift_sasl sasl pandas sqlalchemy pytest
# git clone  https://github.com/cloudera/impyla.git
# cd impyla
# python setup.py build
# sudo python setup.py install
# py.test

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
