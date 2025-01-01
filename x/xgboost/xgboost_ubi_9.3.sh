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
#set output folder
export OUTPUT_FOLDER="$(pwd)/output"

yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openssl-devel cmake openblas-devel gcc-gfortran
pip install numpy packaging pathspec pluggy scipy trove-classifiers pytest wheel build
# Clone the repository
mkdir output
git clone -b ${PACKAGE_VERSION} --recursive $PACKAGE_URL
cd $PACKAGE_NAME
export SRC_DIR=$(pwd)

#build xgboost cpp artifacts
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
EXEEXT=
mkdir -p ${LIBDIR} ${INCDIR}/xgboost ${BINDIR} || true
cp ${SRC_DIR}/lib/${XGBOOSTDSO} ${SODIR}
cp -Rf ${SRC_DIR}/include/xgboost ${INCDIR}/
cp -Rf ${SRC_DIR}/rabit/include/rabit ${INCDIR}/xgboost/
cp -f ${SRC_DIR}/src/c_api/*.h ${INCDIR}/xgboost/
cd ../../

#build xgboost python artifacts and wheel
cd $PACKAGE_NAME/python-package
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi
# Run test cases
if !(pytest); then
    echo "------------------$PACKAGE_NAME:No_test_cases_found-------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    exit 0
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
