#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : hf-xet
# Version          : v1.8.0
# Source repo      : https://github.com/huggingface/xet-core
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
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
PACKAGE_VERSION=${1:-v1.8.0}
PACKAGE_URL=https://github.com/huggingface/xet-core
PACKAGE_DIR=xet-core/hf_xet
CURRENT_DIR=$(pwd)

# Install dependencies
yum install -y python3.12 wget python3.12-pip python3.12-devel gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git openssl openssl-devel cmake perl clang clang-devel make

source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Rust edition 2024 needs a recent stable toolchain
echo "----Installing rust------"
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"

# Clone the repository
cd $CURRENT_DIR
git clone $PACKAGE_URL
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Install python dependencies
python3.12 -m pip install --upgrade pip
python3.12 -m pip install "maturin>=1.7,<2.0" build wheel pytest

# Install
if ! python3.12 -m pip install -e . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Smoke test: the compiled extension must import
if ! python3.12 -c "import hf_xet; print('hf_xet', hf_xet.__file__)" ; then
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
# The upstream pytest suite in hf_xet/tests is not run: it needs network access to the Hugging Face Hub.
