#!/bin/bash 
# -----------------------------------------------------------------------------
#
# Package	    : Pyro4
# Version	    : 4.82
# Source repo	: https://github.com/irmen/Pyro4
# Tested on	    : UBI:9.6
# Language      : python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -ex

PACKAGE_NAME="Pyro4"
PACKAGE_VERSION=${1:-4.82}
PACKAGE_URL="https://github.com/irmen/Pyro4"
PACKAGE_DIR=Pyro4
OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)

echo "Installing dependencies from system repos..."
yum install -qy python3.12 python3.12-devel python3.12-pip git make gcc-toolset-13-gcc 

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

#clone the package
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION


python3.12 -m pip install wheel
python3.12 -m pip install -r requirements.txt
python3.12 -m pip install -r test_requirements.txt

if ! make install; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Pyro4 is an older package, with its last release in 2021, and official support only up to Python 3.10. The existing test suite relies on deprecated or removed APIs and therefore does not run correctly on Python 3.11 or 3.12.For this reason, when building wheels for Python 3.11 and 3.12, the test phase must be skipped.
