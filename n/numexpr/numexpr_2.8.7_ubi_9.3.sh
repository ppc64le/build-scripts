#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : numexpr
# Version       : v2.8.7
# Source repo   : https://github.com/pydata/numexpr.git
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Vikram Kuppala <sai.vikram.kuppala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables

PACKAGE_NAME=numexpr
PACKAGE_VERSION=${1:-v2.8.7}
PACKAGE_URL=https://github.com/pydata/numexpr.git
PACKAGE_DIR=./numexpr

# Install dependencies and tools.
 yum install -y \
    git gcc gcc-c++ make \
    openssl-devel bzip2-devel libffi-devel xz zlib-devel \
    python3.11 python3.11-devel \
    cmake openblas-devel
python3.11 -m ensurepip --upgrade
python3.11 -m pip install --upgrade pip setuptools wheel
python3.11 -m pip --version

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install pytest
python3.11 -m pip  install --upgrade pip setuptools wheel "numpy<2.0"
python3.11 -m pip install -e .
export PYTEST_DISABLE_PLUGIN_AUTOLOAD=1

echo "Forcing compatible pytest version..."
python3.11 -m pip uninstall -y pytest
python3.11 -m pip install "pytest<8"
python3.11 -m pip show pytest



#install
if ! (python3.11 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! (python3.11 -m pytest); then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
