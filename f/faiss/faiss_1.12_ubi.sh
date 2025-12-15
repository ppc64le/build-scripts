#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package           : faiss
# Version           : 1.12.0
# Source repo       : https://github.com/facebookresearch/faiss.git
# Tested on         : RHEL 9.6
# Language          : C++, Python
# Ci-Check      : True
# Script License    : Apache License Version 2.0
# Maintainer        : Madhur Gupta <madhur.gupta2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#

# set -e

PACKAGE_NAME=faiss
PACKAGE_DIR=faiss_build/faiss/build/faiss/python
PACKAGE_VERSION=${1:-1.12.0}
PACKAGE_URL=https://github.com/facebookresearch/faiss.git


echo "Installing dependencies..."

yum install -y \
    python3 python3-devel python3-pip \
    openblas-devel pcre2-devel cmake git \
    autoconf automake libtool gcc-c++ make wget gcc-fortran
yum install -y https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/bison-3.7.4-5.el9.ppc64le.rpm 


echo "Upgrading Python tools..."
python3 -m pip install --upgrade setuptools wheel build numpy


BUILD_DIR=faiss_build
mkdir -p "${BUILD_DIR}" && cd "${BUILD_DIR}" || exit 1


if ! command -v swig &> /dev/null; then
    echo "SWIG not found. Building SWIG from source..."
    if [ ! -d "swig" ]; then
        git clone https://github.com/swig/swig.git
    fi
    cd swig || exit 1
    ./autogen.sh
    ./configure
    make -j"$(nproc)"
    make install
    cd ..
else
    echo "SWIG already installed: $(swig -version | grep 'SWIG Version' | awk '{print $3}')"
fi

swig -version || { echo "SWIG installation failed"; exit 1; }


if [ ! -d "faiss" ]; then
    echo "Cloning FAISS repository..."
    git clone https://github.com/facebookresearch/faiss.git
fi

cd faiss || exit 1

mkdir -p build && cd build || exit 1

cmake .. \
    -DFAISS_ENABLE_PYTHON=ON \
    -DFAISS_ENABLE_GPU=OFF \
    -DBUILD_TESTING=OFF \
    -DPython_EXECUTABLE="$(which python3)" \
    -DBLAS_LIBRARIES="/usr/lib64/libopenblas.so" \
    -DCMAKE_BUILD_TYPE=Release

make -j"$(nproc)"

cd faiss/python

if ! (pip install .); then 
   echo "------------------$PACKAGE_NAME:Failed to build wheel-------------------------------------"
   echo "$PACKAGE_URL $PACKAGE_NAME"
   echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
fi
# Run tests
cd ../../../tests/
pip install pytest scipy
cd ../tests
if ! (pytest); then
     echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails--------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
     exit 2
else
     echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Import_Success"
     exit 0
fi
