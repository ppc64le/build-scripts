#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : py-make
# Version       : v0.1.2
# Source repo   : https://github.com/tqdm/py-make
# Tested on     : UBI 8.5
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Anup Kodlekere / Vedang Wartikar <Vedang.Wartikar@ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="py-make"
PACKAGE_VERSION="${1:-v0.1.2}"  # Updated from v0.1.1 (not available, >5 years old)
PACKAGE_URL="https://github.com/tqdm/py-make"
PACKAGE_AVAILABLE_TAGS="v0.1.2"  # Available git tags for fallback testing

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="git make python36"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# =============================================================================
# OPTIONAL: Custom environment variables (from original script)
# =============================================================================
export TOXENV=py36

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# mkdir -p /home/tester && cd /home/tester
# export TOXENV=py36
# pip3 install tox
# pip3 install .
# tox
# ret=$?
# if [ $ret -ne 0 ] ; then
#   echo "Build & Test failed for python 3.6 environment"
#   echo "Build & Test Success for python 3.6 environment"

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
