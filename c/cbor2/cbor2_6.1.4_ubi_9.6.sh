#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cbor2
# Version          : 6.1.4
# Source repo      : https://github.com/agronholm/cbor2
# Tested on        : UBI:9.6
# Language         : Python, Rust
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Prerna Kumbhar <Prerna.Kumbhar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=cbor2
PACKAGE_VERSION=${1:-6.1.4}
PACKAGE_URL=https://github.com/agronholm/cbor2
PACKAGE_DIR=msgspec

dnf install -y git gcc gcc-c++ make openssl-devel bzip2-devel libffi-devel zlib-devel xz-devel wget tar sqlite-devel python3.11 python3.11-pip python3.11-devel
ln -sf /usr/bin/python3.11 /usr/bin/python3
ln -sf /usr/bin/pip3.11 /usr/bin/pip
ln -sf /usr/bin/pip3.11 /usr/bin/pip3

python3 -m pip install --upgrade pip setuptools wheel pytest hypothesis coverage

# Install Rust toolchain
# cbor2 ships a Rust extension (cbor2._cbor2) compiled via setuptools-rust.
# Without cargo on PATH the build silently produces a pure-Python wheel

echo "-------------------------- Installing Rust toolchain --------------------------"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source "${HOME}/.cargo/env"
export PATH="${HOME}/.cargo/bin:${PATH}"

rustc --version
cargo --version

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME  
git checkout $PACKAGE_VERSION

if ! pip install -e .; then
        echo "------------------$PACKAGE_NAME:install_fails------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_Failed"  
        exit 1
fi

# Run pytest
pytest
if [ $? -eq 0 ]; then
    echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
    exit 0
else
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"
    exit 2
fi
