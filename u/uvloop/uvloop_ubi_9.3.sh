#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : uvloop
# Version       : v0.21.0
# Source repo   : https://github.com/MagicStack/uvloop
# Tested on     : UBI 9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Manya Rusiya <Manya.Rusiya@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=uvloop
PACKAGE_VERSION=${1:-v0.21.0}
PACKAGE_URL=https://github.com/MagicStack/uvloop
PACKAGE_DIR=uvloop


# Install dependencies
yum install -y git python3.12 python3.12-devel python3.12-pip \
    gcc gcc-c++ gcc-gfortran gzip tar make wget xz cmake yum-utils \
    openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel \
    zlib-devel autoconf automake libtool cargo \
    pkgconf-pkg-config fontconfig fontconfig-devel sqlite-devel

# Clone the repository
git clone --recursive $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# Upgrade pip and install build/test dependencies
python3.12 -m pip install --upgrade pip setuptools wheel
python3.12 -m pip install meson meson-python ninja cython pythran "pybind11>=2.13.2"
python3.12 -m pip install numpy==2.0.2 --no-build-isolation
python3.12 -m pip install "scipy>=1.8.0,<1.16.0" --no-build-isolation
python3.12 -m pip install joblib threadpoolctl patchelf pytest build hypothesis tox

# ------------------ Install ------------------
if ! (python3.12 -m pip install .); then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# ------------------ Test ------------------
cd $PACKAGE_NAME

if ! tox -e py312; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
