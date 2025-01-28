#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scikit-learn
# Version       : 1.1.1
# Source repo   : https://github.com/scikit-learn/scikit-learn
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Vinod K<Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scikit-learn
PACKAGE_VERSION=${1:-1.1.1}
PACKAGE_URL=https://github.com/scikit-learn/scikit-learn

echo "Installing dependencies..."
yum install -y gcc gcc-c++ make libtool cmake git wget xz python python-devel zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel libjpeg-turbo-devel gcc-gfortran openblas openblas-devel libgomp


echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

echo "installing pytest...."
pip install pytest 
echo "installing cython.."
pip install cython==0.29.36 
echo "installing numpy.."
pip install numpy==1.23.5 
echo "installing scipy.."
pip install scipy 
echo "installing joblib.."
pip install joblib 
echo "installing threadpoolctl.."
pip install threadpoolctl 
echo "installing meson-python and ninja.."
pip install meson-python ninja  
echo "installing setuptools.."
pip install setuptools==59.8.0

echo "installing..."
if ! (python setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
export PY_IGNORE_IMPORTMISMATCH=1

echo "Testing..."
if ! pytest sklearn/tests/test_random_projection.py; then
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