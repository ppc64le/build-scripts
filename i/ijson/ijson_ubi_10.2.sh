#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : ijson
# Version          : v3.5.1
# Source repo      : https://github.com/ICRAR/ijson.git
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : tejasBadjateIBM <Tejas.Badjate@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=ijson
PACKAGE_VERSION=${1:-v3.5.1}
PACKAGE_URL=https://github.com/ICRAR/ijson.git
PACKAGE_DIR=ijson
CURRENT_DIR=${PWD}

# Update system and install dependencies
yum install -y git make automake autoconf python3.14 python3.14-devel python3.14-pip cmake

yum install gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran -y

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15 (SCL removed in UBI 10 — use PATH export)
# ---------------------------------------------------------------------------
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"

export CC="/opt/rh/gcc-toolset-15/root/usr/bin/gcc"
export CXX="/opt/rh/gcc-toolset-15/root/usr/bin/g++"

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

python3.14 -m pip install build wheel pytest
# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install the package
if ! python3.14 -m pip install .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Run tests 
if ! python3.14 -m pytest; then
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