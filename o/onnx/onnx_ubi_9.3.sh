#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnx
# Version          : v1.17.0
# Source repo      : https://github.com/onnx/onnx
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
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
PACKAGE_VERSION=${1:-v1.17.0}
PACKAGE_URL=https://github.com/onnx/onnx
PACKAGE_DIR=onnx

echo "Installing dependencies..."
yum install -y git make libtool  gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran libevent-devel zlib-devel openssl-devel clang python3-devel python3.12 python3.12-devel python3.12-pip cmake openblas openblas-devel
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
source /opt/rh/gcc-toolset-13/enable

# Set library paths and package configuration paths
export LD_LIBRARY_PATH="/usr/lib64:/usr/local/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="/usr/lib/pkgconfig:$PKG_CONFIG_PATH"
export CMAKE_PREFIX_PATH="/usr:/usr/local:$CMAKE_PREFIX_PATH"

echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive
echo "installing python dependencies...."
pip3.12 install pytest nbval pythran
echo "installing numpy.."
pip3.12 install numpy==2.0.2
echo "installing cython.."
pip3.12 install cython
echo "installing scipy.."
pip3.12 install scipy==1.15.2
echo "installing parameterized.."
pip3.12 install parameterized
echo "installing protobuf dependencies...."
pip3.12 install protobuf==4.25.3

echo "installing..."
if ! pip3.12 install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Skipping test due to missing 're2/stringpiece.h' header file. Even after attempting to manually build RE2, the required header file could not be found.
if ! pytest --ignore=onnx/test/reference_evaluator_backend_test.py --ignore=onnx/test/test_backend_reference.py --ignore=onnx/test/reference_evaluator_test.py; then    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
