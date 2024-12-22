#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : imbalanced-learn
# Version       : 0.12.2
# Source repo   : https://github.com/scikit-learn-contrib/imbalanced-learn.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=imbalanced-learn
PACKAGE_VERSION=${1:-0.12.2}
PACKAGE_URL=https://github.com/scikit-learn-contrib/imbalanced-learn.git

yum install -y gcc gcc-c++ gcc-gfortran git make openblas atlas diffutils patch  python-devel openssl-devel openssl

git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Installing Scipy
if !(pip list | grep scipy) ;then
	echo "installing scipy"
	git clone https://github.com/scipy/scipy.git
	cd scipy/
	git checkout v1.10.1
	git submodule update --init
	pip install Cython==0.29.37 'numpy<1.23' 'setuptools<60.0' pybind11 pytest pythran  wheel
	pip install Cython numpy setuptools pybind11 pytest pythran  wheel
	ln -s /usr/lib64/atlas/libtatlas.so.3 /usr/lib64/atlas/libtatlas.so
	ln -s /usr/lib64/libopenblas.so.0 /usr/lib64/libopenblas.so
	python3 setup.py build
	python3 setup.py install
	cd ..
else
   echo "scipy already installed"
fi

#Installing scikit-learn
if !(pip list |grep scikit-learn); then
	echo "installing scikit-learn"
	git clone https://github.com/scikit-learn/scikit-learn.git
	cd scikit-learn/
	git checkout 1.3.2
	python3 setup.py install
	cd ..
else 
 echo "scikit-learn already installed"
fi

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! pytest; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
