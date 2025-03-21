#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scipy
# Version       : v1.15.2
# Source repo   : https://github.com/scipy/scipy
# Tested on     : UBI 9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=scipy
PACKAGE_VERSION=${1:-v1.15.2}
PACKAGE_URL=https://github.com/scipy/scipy
PACKAGE_DIR=scipy

yum install -y git make cmake wget python3.12 python3.12-devel python3.12-pip openblas openblas-devel pkgconfig atlas

yum install gcc-toolset-13 -y
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
gcc --version

ln -sf /usr/bin/python3.12 /usr/bin/python

python -m pip install beniget==0.4.2.post1  Cython==3.0.11 gast==0.6.0 meson==1.6.0 meson-python==0.17.1 numpy==2.0.2 packaging pybind11 pyproject-metadata pythran==0.17.0 setuptools==75.3.0 pooch pytest build wheel hypothesis highspy  array_api_extra array_api_strict ninja patchelf>=0.11.0

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

export OpenBLAS_HOME="/usr/include/openblas"
export SITE_PACKAGE_PATH=/usr/local/lib/python3.12/site-packages

if ! python -m pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

export PY_IGNORE_IMPORTMISMATCH=1
cd ..

if ! (pytest $PACKAGE_NAME); then
    echo "------------------$PACKAGE_NAME::Install_success_but_test_Fails-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
