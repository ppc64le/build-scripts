#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : uvtools
# Version       : v0.2.0
# Source repo   : https://github.com/HERA-Team/uvtools
# Tested on     : UBI 9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Salil Verlekar <Salil.Verlekar2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=uvtools
PACKAGE_VERSION=${1:-v0.2.0}
PACKAGE_URL=https://github.com/HERA-Team/uvtools

PYTHON_VERSION=3.11

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# install core dependencies
yum install -y python$PYTHON_VERSION python$PYTHON_VERSION-pip python$PYTHON_VERSION-devel gcc-c++ gcc-gfortran gcc-toolset-12 openblas-devel git

source /opt/rh/gcc-toolset-12/enable

# clone source repository
git clone --recursive $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# install dependency
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm -y
yum install -y hdf5-devel

python$PYTHON_VERSION -m venv /usr/local/uvtools-python
source /usr/local/uvtools-python/bin/activate

python3 -m pip install h5py==3.11.0

# build and install
if ! python3.11 -m pip install . ; then
        echo "------------------$PACKAGE_NAME:build_&_install_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Install_Fails"
        exit 1
else
        echo "------------------$PACKAGE_NAME:build_&_install_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Install_Success"
fi

cd ..

# test after installation
python3 -m pip show $PACKAGE_NAME
if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Success---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     deactivate
     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi
