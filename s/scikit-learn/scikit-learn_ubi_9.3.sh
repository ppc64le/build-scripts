#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scikit-learn
# Version       : 1.5.2
# Source repo   : https://github.com/scikit-learn/scikit-learn.git
# Tested on     : UBI 9.3
# Language      : Python, Cython, C++
# Travis-Check  : False
# Script License: Apache License 2.0
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scikit-learn
PACKAGE_VERSION=${1:-1.5.2}
PACKAGE_URL=https://github.com/scikit-learn/scikit-learn.git

yum install -y python python-pip python-devel openblas-devel gcc-toolset-13 git

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# install scikit-learn dependencies and build dependencies
pip install wheel numpy scipy cython meson-python
pip install ninja pytest>=7.1.2  joblib threadpoolctl


# build the project with pip and install
if ! pip install . --no-build-isolation; then
        echo "------------------$PACKAGE_NAME:build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"
fi

# test using pytest - set below flag as suggested in GitHub forums to resolve ImportPathMismatchError
export PY_IGNORE_IMPORTMISMATCH=1
if ! pytest sklearn/tests/test_random_projection.py ; then
        echo "------------------$PACKAGE_NAME:test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME "
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Fail |  Test_Fails"
        exit 2
else
        echo "------------------$PACKAGE_NAME:test_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME "
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | Github | Pass |  Test_Success"
	exit 0
fi
