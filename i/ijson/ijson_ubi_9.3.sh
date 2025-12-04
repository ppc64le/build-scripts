#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ijson
# Version          : 3.4.0
# Source repo      : https://github.com/ICRAR/ijson.git
# Tested on        : UBI:9.3
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shivansh.S1 <Shivansh.S1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=ijson
PACKAGE_VERSION=${1:-v3.4.0}
PACKAGE_URL=https://github.com/ICRAR/ijson.git
PACKAGE_DIR=ijson
CURRENT_DIR=${PWD}

# Update system and install dependencies
yum install -y gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran git make automake autoconf python3 python3-devel python3-pip cmake

source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

#install yajl from source
git clone https://github.com/lloyd/yajl.git
cd yajl
mkdir build
cd build
cmake ..
make -j$(nproc)
make install
export LD_LIBRARY_PATH=$(find "$(pwd)" -maxdepth 1 -type d -name "yajl-*" -exec realpath {}/lib \;):$LD_LIBRARY_PATH
cd $CURRENT_DIR

pip install build wheel pytest
# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install the package
if ! pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run tests 
if ! pytest; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass | Both_Install_and_Test_Success"
    exit 0
fi