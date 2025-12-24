#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : regex
# Version          : 2024.11.6
# Source repo      : https://github.com/mrabarnett/mrab-regex
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : ICH <OpenSource-Edge-for-IBM-Tool-1>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=regex
PACKAGE_VERSION=${1:-2024.11.6}
PACKAGE_URL=https://github.com/mrabarnett/mrab-regex
PACKAGE_DIR=mrab-regex

# Install dependencies
yum install -y git python3 python3-devel.ppc64le gcc-toolset-13 make wget sudo cmake
pip3 install pytest tox nox

export PATH=$PATH:/usr/local/bin/
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_DIR
git checkout $PACKAGE_VERSION

#install
if ! (python3 -m pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# test
if (python3 -m unittest discover); then
    echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
    exit 0
else
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"
    exit 2
fi
