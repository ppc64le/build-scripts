#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : alabaster
# Version          : 1.0.0
# Source repo      : https://github.com/sphinx-doc/alabaster
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer    : ICH <OpenSource-Edge-for-IBM-Tool-1>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#set -ex

# Variables
PACKAGE_NAME=alabaster
PACKAGE_VERSION=${1:-1.0.0}
PACKAGE_URL=https://github.com/sphinx-doc/alabaster
PACKAGE_DIR=alabaster

# Install dependencies
yum install -y git python3.12 python3.12-devel python3.12-pip gcc-toolset-13 make wget sudo cmake
python3.12 -m pip install pytest tox nox

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=GitHub

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install
if ! (python3.12 -m pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi


# no test to run
