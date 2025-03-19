#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : contourpy
# Version          : v1.3.1
# Source repo      : https://github.com/contourpy/contourpy
# Tested on     : UBI:9.5
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Prathamesh Korgaonkar <Prathamesh.Korgaonkar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=contourpy
PACKAGE_VERSION=${1:-v1.3.1}
PACKAGE_URL=https://github.com/contourpy/contourpy
PACKAGE_DIR="$(pwd)/$PACKAGE_NAME"

echo "Installing dependencies...."
yum install -y python3.11 python3.11-pip python3.11-devel gcc gcc-c++ make cmake zlib libjpeg-turbo openssl-devel unzip
echo "Installing dependencies...."
yum install -y git zlib-devel libjpeg-turbo-devel wget sudo gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran 

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

ln -sf /usr/bin/python3.11 /usr/bin/python
ln -sf /usr/bin/python3.11 /usr/bin/python3
python -m pip install pytest wurlitzer matplotlib

if ! command -v rustc &> /dev/null
then
    wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
    tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
    cd rust-1.75.0-powerpc64le-unknown-linux-gnu
    sudo ./install.sh
    export PATH=$HOME/.cargo/bin:$PATH
    rustc -V
    cargo -V
    cd ../
fi

echo "Cloning the repo..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Installing the package..."
if !  python -m pip install . ; then
    echo "------------------$PACKAGE_NAME:install_fails------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Github | Fail | Install_Failed"
    exit 1
fi

echo "Running Pytest..."
if ! python -m pytest ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_failed---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Failed"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
