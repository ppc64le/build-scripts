#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : LightGBM
# Version          : 3.3.2
# Source repo      : https://github.com/microsoft/LightGBM.git
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=LightGBM
PACKAGE_VERSION=${1:-v3.3.2}
PACKAGE_URL=https://github.com/microsoft/LightGBM.git

# Install dependencies
yum install -y git gcc gcc-c++ cmake make wget openssl-devel bzip2-devel libffi-devel zlib-devel python-devel python-pip libjpeg-devel gcc-gfortran openblas atlas

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#set environment
export CC=`which gcc`
export CXX=`which g++`
git submodule update --init

#Installing Scipy
if !(pip list | grep scipy) ;then
        echo "installing scipy"
        git clone https://github.com/scipy/scipy.git
        cd scipy/
        git checkout v1.10.1
        git submodule update --init
        pip install Cython==0.29.37 'numpy<1.23' 'setuptools<60.0' pybind11 pytest pythran  wheel
        pip install Cython setuptools pybind11 pytest pythran  wheel numpy==1.19.5
        ln -s /usr/lib64/atlas/libtatlas.so.3 /usr/lib64/atlas/libtatlas.so
        ln -s /usr/lib64/libopenblas.so.0 /usr/lib64/libopenblas.so
        python3 setup.py install
        cd ..
else
   echo "scipy already installed"
fi

#Installing scikit-learn
if !(pip list |grep scikit-learn ); then
        echo "installing scikit-learn"
        git clone https://github.com/scikit-learn/scikit-learn.git
        cd scikit-learn/
        git checkout 1.1.3
        python3 setup.py install
        cd ..
else
 echo "scikit-learn already installed"
fi

#install necessary Python packages
pip install setuptools numpy==1.19.5 pandas==1.4.2 build joblib psutil pillow matplotlib

#Install
# Set the path to the python-package directory
cd python-package
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit
fi

# Run test cases
if !(pytest -v /LightGBM/tests -k "not test_contribs_sparse_multiclass"); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
