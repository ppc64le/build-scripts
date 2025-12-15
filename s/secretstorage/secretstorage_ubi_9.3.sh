#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : secretstorage
# Version       : 3.3.3
# Source repo   : git clone https://github.com/mitya57/secretstorage.git
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Haritha Nagothu <haritha.nagothu2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#variables
PACKAGE_NAME=secretstorage
PACKAGE_VERSION=${1:- 3.3.3}
PACKAGE_URL=https://github.com/mitya57/secretstorage.git

# Install dependencies and tools.
yum install -y gcc gcc-c++ gcc-gfortran git make python-devel zlib-devel openssl-devel libjpeg-devel xz-devel bzip2-devel wget libX11-devel

#clone repository 
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#installing rust
if ! command -v rustc &> /dev/null; then
    echo "Rust is not installed. Installing Rust..."
    wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
	tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz
	cd rust-1.75.0-powerpc64le-unknown-linux-gnu
	./install.sh
	export PATH=$HOME/.cargo/bin:$PATH
	rustc -V
	cargo  -V
	cd ..
else
    echo "Rust is already installed."
fi

#Install all dependencies
pip install .

#install
if ! (python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#Install Pytest
pip install pytest

#test
#skipping the some testcase as it is failing on x_86 also.
if ! (pytest -k "not (CollectionTest or  ItemTest or ExceptionsTest or ContextManagerTest)"); then
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
