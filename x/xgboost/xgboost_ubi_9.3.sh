#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : xgboost
# Version       : 1.6.2
# Source repo :  https://github.com/dmlc/xgboost
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e
 
# Variables
PACKAGE_NAME=xgboost
PACKAGE_VERSION=${1:-v1.6.2}
PACKAGE_URL=https://github.com/dmlc/xgboost
PACKAGE_DIR=xgboost/python-package
OUTPUT_FOLDER="$(pwd)/output"
 
echo "PACKAGE_NAME: $PACKAGE_NAME"
echo "PACKAGE_VERSION: $PACKAGE_VERSION"
echo "PACKAGE_URL: $PACKAGE_URL"
echo "OUTPUT_FOLDER: $OUTPUT_FOLDER"
 
# Install dependencies
echo "Installing dependencies..."
yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openssl-devel cmake openblas-devel gcc-gfortran
pip install numpy packaging pathspec pluggy scipy trove-classifiers pytest wheel build
 
# Clone the repository
echo "Cloning the repository..."
mkdir -p output
git clone -b ${PACKAGE_VERSION} --recursive $PACKAGE_URL
cd $PACKAGE_NAME
export SRC_DIR=$(pwd)
echo "SRC_DIR: $SRC_DIR"
 
# Build xgboost cpp artifacts
echo "Building xgboost cpp artifacts..."
cd ${SRC_DIR}
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${OUTPUT_FOLDER} ..
make -j$(nproc)
 
LIBDIR=${OUTPUT_FOLDER}/lib
INCDIR=${OUTPUT_FOLDER}/include
BINDIR=${OUTPUT_FOLDER}/bin
SODIR=${LIBDIR}
XGBOOSTDSO=libxgboost.so

mkdir -p ${LIBDIR} ${INCDIR}/xgboost ${BINDIR} || true
cp ${SRC_DIR}/lib/${XGBOOSTDSO} ${SODIR}
cp -Rf ${SRC_DIR}/include/xgboost ${INCDIR}/
cp -Rf ${SRC_DIR}/rabit/include/rabit ${INCDIR}/xgboost/
cp -f ${SRC_DIR}/src/c_api/*.h ${INCDIR}/xgboost/
cd ../../
 
# Build xgboost python artifacts and wheel
echo "Building xgboost Python artifacts and wheel..."
cd "$(pwd)/$PACKAGE_DIR"
echo "Current directory: $(pwd)"
 
if ! (python3 setup.py install); then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi
 
echo "Build and installation completed successfully."
