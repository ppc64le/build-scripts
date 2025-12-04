#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ctranslate2
# Version       : v4.5.0
# Source repo   : https://github.com/OpenNMT/CTranslate2
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Salil Verlakar <Salil.Verlekar2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ========== platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such case, please
# contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
PACKAGE_DIR=CTranslate2/python
PACKAGE_NAME=ctranslate2
PACKAGE_VERSION=${1:-v4.5.0}
PACKAGE_URL=https://github.com/OpenNMT/CTranslate2
CURRENT_DIR=$(pwd)

# Install dependencies.
yum install -y gcc gcc-c++ make cmake git \
    autoconf automake libtool patch \
    redhat-rpm-config rpm-build \
    openblas-devel libomp-devel \
    pybind11-devel \
    python3.11 python3.11-devel python3.11-pip

# Clone the ctranslate2 source
git clone --recursive ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout  ${PACKAGE_VERSION}
git submodule update --init --recursive

cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_MKL=OFF \
    -DWITH_DNNL=ON \
    -DWITH_CUDA=OFF \
    -DWITH_CUDNN=OFF \
    -DWITH_OPENBLAS=ON \
    -DWITH_DNNL=OFF \
    -DOPENMP_RUNTIME=COMP \
    -DENABLE_CPU_DISPATCH=OFF \
    -DOPENBLAS_INCLUDE_DIR=/usr/include/openblas \
    -DBLAS_LIBRARIES=/usr/lib64/libopenblas.so

make -j4
make install
ldconfig

# Install the ctranslate2 requirements.
python3.11 -m pip install -r install_requirements.txt

# Build and install ctranslate2
if ! python3.11 -m pip install .; then
        echo "------------------$PACKAGE_NAME:build_install_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_install_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub  | Pass |  Build_Success"
fi

# Test after installation
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/CTranslate2/python/
python3.11 -c "import ctranslate2; print(ctranslate2.__version__)"
python3.11 -m pip install pytest

if pytest tests/test_storage_view.py; then
     echo "------------------$PACKAGE_NAME::Test_Success---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi
