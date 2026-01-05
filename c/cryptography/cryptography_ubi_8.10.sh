#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : cryptography
# Version          : 43.0.3
# Source repo      : https://github.com/pyca/cryptography/
# Tested on        : UBI 8.10
# Language         : Python
# Ci-Check     : False
# Script License   : Apache License, Version 2 or later
# Maintainer       : Balavva Mirji <Balavva.Mirji@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e 
PACKAGE_NAME=cryptography
PACKAGE_VERSION=${1:-43.0.3}
PACKAGE_URL=https://github.com/pyca/cryptography/

# Install required dependencies
yum install gcc gcc-c++ make git wget python3.11 python3.11-devel python3.11-pip openssl-devel libffi-devel -y 
python3.11 -m pip install build maturin cffi

# Instal cargo
export RUST_VERSION="1.76.0"
printf -- 'Installing Rust \n'
wget -q -O rustup-init.sh https://sh.rustup.rs
bash rustup-init.sh -y
export PATH=$PATH:$HOME/.cargo/bin
rustup toolchain install ${RUST_VERSION}
rustup default ${RUST_VERSION}
rustc --version | grep "${RUST_VERSION}"

# Add llvm-preview 
rustup component add llvm-tools-preview

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init --recursive

# Clone test vectors
git clone https://github.com/C2SP/wycheproof.git
git clone https://github.com/C2SP/x509-limbo.git 

# Updating backend to uv|virtualenv
sed -i 's/venv_backend="uv"/venv_backend="uv|virtualenv"/' noxfile.py

# Install nox
python3.11 -m pip install -c ci-constraints-requirements.txt 'nox'

# Installation
if ! nox -v --install-only ; then
    echo "------------------$PACKAGE_NAME::Installation_Fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Installation_Fails"
    exit 1
fi

# Creation of wheel
python3.11 -m build --wheel

# Running tests
export NOXSESSION=rust
if ! nox --no-install --  --color=yes --wycheproof-root=wycheproof --x509-limbo-root=x509-limbo ; then
    echo "------------------$PACKAGE_NAME::Cryptography_Rust_Test_Fails-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Installation_Success_but_Cryptography_Rust_Test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME::Installation_and_Cryptography_Rust_Test_Success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass | Installation_and_Cryptography_Rust_Test_Success"
    exit 0
fi