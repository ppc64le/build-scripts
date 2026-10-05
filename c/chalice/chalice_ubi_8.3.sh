#!/bin/bash -e
# -----------------------------------------------------------------------------
# Package       : chalice
# Version       : 1.24.2,1.22.4 ,1.21.8
# Source repo   : https://github.com/aws/chalice
# Tested on     : UBI 8.3
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Arumugam N S <asellappen@yahoo.com> / Priya Seth<sethp@us.ibm.com>
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# REQUIRED: Package metadata
# =============================================================================
PACKAGE_NAME="chalice"
PACKAGE_VERSION="${1:-1.24.2,1.22.4 ,1.21.8}"
PACKAGE_URL="https://github.com/aws/chalice"

# =============================================================================
# REQUIRED: Dependencies
# =============================================================================
RH_DEP_PKGS="gcc git make openssl-devel.ppc64le python36-devel"
DEB_DEP_PKGS=""
SLES_DEP_PKGS=""

# REVIEW - following code was not auto-migrated. See PORTING-NOTES.md for details.
# if [ -z "$1" ]; then
#   export VERSION=master
#   export VERSION=$1
# if [ -d "chalice" ] ; then
#   rm -rf chalice
# git clone https://github.com/aws/chalice
# cd chalice
# git checkout $VERSION
# ret=$?
# if [ $ret -eq 0 ] ; then
#  echo "$Version found to checkout "
#  echo "$Version not found "
#  exit
# pip3 install pytest
# pip3 install -r requirements-dev.txt -r requirements-docs.txt
# pip3 install -e .
# mv  tests/integration/test_package.py tests/integration/ignore_test_package.py
# make prcheck
# ret=$?
# if [ $ret -ne 0 ] ; then
#   echo "make failed for python 3.6 environment"
#   echo "make Success for python 3.6 environment"
# if  [ $VERSION != "1.21.8" ] ; then
#   npm install -g aws-cdk
#   ret=$?
#   if [ $ret -ne 0 ] ; then
#     echo "npm aws-cdk install failed "
#     echo "npm aws-cdk  Success "
#   pip3 install -e .[cdk]
#   python3.6 -m pytest tests/functional/cdk
#   ret=$?
#   if [ $ret -ne 0 ] ; then
#     echo "cdktests Test failed "
#     echo "cdktests Test Success "

# =============================================================================
# Execute the build (invokes the Python template)
# =============================================================================
source "${SCRIPT_DIR}/../../templates/python.sh"
