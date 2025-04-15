#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : python-blosc
# Version          : 1.11.1
# Source repo      : https://github.com/Blosc/python-blosc.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=python-blosc
PACKAGE_VERSION=${1:-v1.11.1}
PACKAGE_URL=https://github.com/Blosc/python-blosc.git

# Install necessary system dependencies
yum install -y git gcc gcc-c++ make cmake wget openssl-devel bzip2-devel libffi-devel libjpeg-devel zlib-devel python-devel python-pip

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME  # Change directory to the cloned repository
git checkout $PACKAGE_VERSION  # Checkout the specified version

#Print current directory
echo "Current directory for $PACKAGE_NAME: $(pwd)"

#Install additional dependencies
git clone https://github.com/blosc/c-blosc.git
cd c-blosc
mkdir build
cd build
cmake .. -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/usr/local
make
make install
export USE_SYSTEM_BLOSC=1

#Return to python-blosc directory
cd ../..

# Install additional dependencies
pip install setuptools build scikit-build cmake ninja py-cpuinfo Pillow pytest numpy

#install
if ! pip install . --use-feature=in-tree-build ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#run tests
if !(python3 -m unittest discover  -p "test.py") ; then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
