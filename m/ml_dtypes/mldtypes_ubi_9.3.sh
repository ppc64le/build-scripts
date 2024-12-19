#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : ml_dtypes
# Version       : 0.1.0
# Source repo :  https://github.com/jax-ml/ml_dtypes.git
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
PACKAGE_NAME=ml_dtypes
PACKAGE_VERSION=${1:-0.1.0}
PACKAGE_URL=https://github.com/jax-ml/ml_dtypes.git

yum install -y git wget gcc gcc-c++ python python3-devel python3 python3-pip openssl-devel cmake zip unzip
pip3 install absl-py numpy pytest pybind11

#Install eigen
wget https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.zip
unzip eigen-3.4.0.zip
cp -r eigen-3.4.0/Eigen/ /usr/local/include

#Build ml_dtypes
ML_DTYPES_VERSION=0.5.0
git clone -b v${ML_DTYPES_VERSION} https://github.com/jax-ml/ml_dtypes.git
cd ml_dtypes
git submodule init
git submodule update

#Install 
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

pip install ml_dtypes
#Run tests
if !(pytest); then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
