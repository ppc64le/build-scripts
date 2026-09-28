#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : graphviz
# Version       : 0.20.2
# Source repo   : https://github.com/xflr6/graphviz
# Tested on     : UBI:9.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Abhinav Kumar <abhinav.kumar25@ibm.com>
# -----------------------------------------------------------------------------
# WARNING: Auto-migrated script - REVIEW REQUIRED
#   - Original: graphviz_ubi_9.3.sh
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="graphviz"
PACKAGE_VERSION="${1:-0.20.2}"
PACKAGE_URL="https://github.com/xflr6/graphviz"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="autoconf automake bzip2 bzip2-devel cargo cmake fontconfig-devel.ppc64le fontconfig.ppc64le gcc gcc-c++ git gzip info.ppc64le libffi-devel libtool make openblas-devel openssl-devel pkgconf-pkg-config.ppc64le python-devel sqlite-devel tar unzip wget xz yum-utils zip zlib-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# Custom test command (extracted from original script)
custom_test_command() {
    # TODO: Review and update test commands
    pip3 install tox flake8 pep8-naming wheel twine pytest-mock pytest-cov coverage sphinx sphinx-autodoc-typehints sphinx-rtd-theme
}

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# pip3 install tox flake8 pep8-naming wheel twine pytest-mock pytest-cov coverage sphinx sphinx-autodoc-typehints sphinx-rtd-theme
# pip install pytest==7
# pip install .
# if ! (python3 setup.py install); then
# if ! (python3 run-tests.py --skip-exe --cov-append) ; then

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../v2-templates/python.sh"
