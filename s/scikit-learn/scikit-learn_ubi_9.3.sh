#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scikit-learn
# Version       : 1.6.1
# Source repo   : https://github.com/scikit-learn/scikit-learn.git
# Tested on     : UBI 9.3
# Language      : Python, Cython, C++
# Travis-Check  : False
# Script License: Apache License 2.0
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scikit-learn
PACKAGE_VERSION=${1:-1.6.1}
PACKAGE_URL=https://github.com/scikit-learn/scikit-learn.git

yum install -y python python-pip python-devel openblas-devel gcc gcc-c++ gcc-toolset-13 git

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# install scikit-learn dependencies and build dependencies
pip install wheel numpy==2.0.2 scipy cython meson-python
pip install ninja pytest>=7.1.2  joblib threadpoolctl patchelf>=0.11.0 setuptools

#install
if ! pip install --editable . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# test using pytest - set below flag as suggested in GitHub forums to resolve ImportPathMismatchError
export PY_IGNORE_IMPORTMISMATCH=1

if ! pytest sklearn/tests/test_random_projection.py; then
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
