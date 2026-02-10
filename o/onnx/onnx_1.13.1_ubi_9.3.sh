#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnx
# Version          : v1.13.1
# Source repo      : https://github.com/onnx/onnx
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K<Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=onnx
PACKAGE_VERSION=${1:-v1.13.1}
PACKAGE_URL=https://github.com/onnx/onnx

echo "Installing dependencies..."
yum install -y git make libtool gcc-c++ libevent-devel zlib-devel openssl-devel python3 python3-devel cmake gcc-gfortran openblas openblas-devel python3-pip

export CC=/usr/bin/gcc
export CXX=/usr/bin/g++

echo "Downloading and installing protobuf-c"
git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf
git checkout v3.20.2
git submodule update --init --recursive
mkdir build_source && cd build_source
cmake ../cmake -Dprotobuf_BUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_SYSCONFDIR=/etc -DCMAKE_POSITION_INDEPENDENT_CODE=ON -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release
echo "Building..."
make -j$(nproc)
echo "Installing..."
make install
cd ../..

echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

echo "installing python dependencies...."
pip install pytest nbval pythran
echo "installing numpy.."
pip install numpy==1.24.3
echo "installing cython.."
pip install "cython<3.0"
echo "installing scipy.."
pip install "scipy>=1.11,<1.12"
echo "installing parameterized.."
pip install parameterized

echo "installing..."
if ! pip install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! pytest --ignore=onnx/test/reference_evaluator_test.py --ignore=onnx/test/test_backend_reference.py --ignore=onnx/test/reference_evaluator_backend_test.py ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
