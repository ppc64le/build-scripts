#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package          : snappy
# Version          : 1.2.2
# Source repo      : https://github.com/google/snappy
# Tested on        : UBI:9.3
# Language         : C++,Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Ramnath Nayak <Ramnath.Nayak@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------


# Variables
PACKAGE_NAME=snappy
PACKAGE_VERSION=${1:-1.2.2}
PACKAGE_URL=https://github.com/google/snappy
PACKAGE_DIR=text
WORK_DIR=$(pwd)


# Install necessary system dependencies
yum install -y git gcc gcc-c++ make cmake wget openssl-devel python-devel python-pip bzip2-devel libffi-devel zlib-devel meson ninja-build gcc-gfortran openblas-devel libjpeg-devel zlib-devel libtiff-devel freetype-devel libomp-devel zip unzip sqlite-devel

git clone -b $PACKAGE_VERSION $PACKAGE_URL
cd snappy
git submodule update --init

mkdir -p local/snappy
export PREFIX=$(pwd)/local/snappy
mkdir build
cd build

cmake -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_INSTALL_LIBDIR=lib \
      ..
make -j$(nproc)
make install
cd ..

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/s/snappy/pyproject.toml

pip install setuptools wheel tox

#install
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#run tests
if !(tox -e py3); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
