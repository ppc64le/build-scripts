#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scikit-image
# Version       : v0.24.0
# Source repo   : https://github.com/scikit-image/scikit-image
# Tested on     : UBI 9.3
# Language      : Python, Cython, C, C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Salil Verlekar <Salil.Verlekar2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=scikit-image
PACKAGE_VERSION=${1:-v0.24.0}
PACKAGE_URL=https://github.com/scikit-image/scikit-image

OS_NAME=`cat /etc/os-release | grep "PRETTY" | awk -F '=' '{print $2}'`

# install core dependencies
yum install -y gcc gcc-c++ gcc-gfortran pkg-config openblas-devel git python3.11 python3.11-pip python3.11-devel gcc-toolset-12 zlib-devel libjpeg-turbo-devel

source /opt/rh/gcc-toolset-12/enable

# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# Create a virtualenv named ``skimage-dev`` that lives outside of the repository.
mkdir ~/envs
python3.11 -m venv ~/envs/skimage-dev
# Activate it
source ~/envs/skimage-dev/bin/activate

# Install main development and runtime dependencies
python3.11 -m pip install -r requirements.txt

# Install build dependencies of scikit-image
python3.11 -m pip install -r requirements/build.txt

# build and install
if ! python3.11 -m pip install -e . --no-build-isolation; then
        echo "------------------$PACKAGE_NAME:build_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"

        python3.11 -m pip show scikit-image
        python3.11 -c "import skimage; print(skimage.__version__)"
        if [ $? == 0 ]; then
                echo "------------------$PACKAGE_NAME:install_success-------------------------"
                echo "$PACKAGE_VERSION $PACKAGE_NAME"
                echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_Success"
        else
                echo "------------------$PACKAGE_NAME:install_fails---------------------"
                echo "$PACKAGE_URL $PACKAGE_NAME"
                echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
                exit 1
        fi
fi

# test some functionality
if ! pytest skimage/filters/tests/test_unsharp_mask.py; then
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
else
     echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     deactivate
     exit 0
fi
