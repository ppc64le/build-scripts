#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cymem
# Version          : release-v2.0.16
# Source repo      : https://github.com/explosion/cymem
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=cymem
PACKAGE_VERSION=${1:-release-v2.0.16}
PACKAGE_URL=https://github.com/explosion/cymem
PACKAGE_DIR=cymem
CURRENT_DIR="${PWD}"

# Install dependencies
yum install -y git python3.12 python3.12-devel python3.12-pip gcc-toolset-13 make

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# pyproject.toml requires cython>=3.1
python3.12 -m pip install --upgrade pip setuptools wheel pytest "cython>=3.1"

# Clone the repo
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

if ! python3.12 -m pip install . --no-build-isolation; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run the packaged tests against the installed build (as upstream CI does),
# from outside the source tree so the unbuilt source package is not imported.
cd "$CURRENT_DIR"

if ! python3.12 -m pytest --pyargs cymem -Werror ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
