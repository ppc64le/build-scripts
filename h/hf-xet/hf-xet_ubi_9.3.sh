#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : hf-xet
# Version          : v1.1.0
# Source repo      : https://github.com/huggingface/xet-core
# Tested on        : UBI:9.3
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod.K1 <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=hf-xet
PACKAGE_VERSION=${1:-v1.1.0}
PACKAGE_URL=https://github.com/huggingface/xet-core
PACKAGE_DIR=xet-core/hf_xet
CURRENT_DIR=$(pwd)

# Install dependencies
yum install -y python3.12 wget python3.12-pip python3.12-devel gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git openssl openssl-devel

source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

echo "----Installing rust------"
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

#install python dependencies
pip3.12 install numpy cython build pytest

sed -i "s/^version *= *.*/version = \"${PACKAGE_VERSION#v}\"/" Cargo.toml

pip3.12 install maturin build wheel

#install
if ! pip3.12 install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Install_Success"
    exit 0
fi
#Skipped the test part as there are no test files to run the tests.
