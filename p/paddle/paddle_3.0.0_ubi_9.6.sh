#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : Paddle
# Version       : v3.0.0
# Source repo   : https://github.com/PaddlePaddle/Paddle.git
# Tested on     : UBI:9.6
# Language      : Python , C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prerna Kumbhar <Prerna.Kumbhar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
################################# Paddle ##################################

PACKAGE_NAME=Paddle
PACKAGE_URL=https://github.com/PaddlePaddle/Paddle.git
PACKAGE_VERSION=${1:-v3.0.0}
PYTHON_VERSION=${2:-3.12}
export wdir=`pwd`

yum install -y git wget python${PYTHON_VERSION}-devel python${PYTHON_VERSION}-pip python${PYTHON_VERSION}-devel python${PYTHON_VERSION}-pip java-17-openjdk java-17-openjdk-devel openblas-devel gcc gcc-c++ make gcc-gfortran patch zlib-devel libjpeg-devel libtiff-devel freetype-devel cmake

ln /usr/bin/pip${PYTHON_VERSION} /usr/bin/pip3 -f && ln /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 -f &&  ln /usr/bin/pip${PYTHON_VERSION} /usr/bin/pip -f && ln /usr/bin/python${PYTHON_VERSION} /usr/bin/python -f

pip3 install --upgrade pip  wheel patchelf numpy protobuf scikit-learn

# echo "------------cloning Paddle----------------"
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

echo "------------applying patch----------------"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/paddle/paddle_v3.0.0.patch
git apply paddle_v3.0.0.patch
pip install -r python/requirements.txt


echo "------------------Building Paddle------------------------"
mkdir build
cd build
cmake -DCMAKE_CXX_FLAGS="-Wno-stringop-overflow -Wno-error=overloaded-virtual" .. 
make -j$(nproc)

echo "------------------Installing Paddle wheel------------------------"
pip install python/dist/paddlepaddle*.whl

echo "------------------Testing Paddle import------------------------"
if python -c "import paddle; print('paddle version:', paddle.__version__)"; then
    echo "TEST PASSED"
else
    echo "TEST FAILED"
    exit 1
fi
