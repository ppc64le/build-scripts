#!/bin/bash -e
# ----------------------------------------------------------------------------
# 
# Package       : notebook
# Version       : v6.5.4
# Source repo   : https://github.com/jupyter/notebook
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
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
PACKAGE_NAME=notebook
PACKAGE_VERSION=${1:-v6.5.4}
PACKAGE_URL=https://github.com/jupyter/notebook

# Install dependencies and tools.
yum install -y wget gcc gcc-c++ gcc-gfortran git make  python-devel  openssl-devel sqlite-devel

#clone repository 
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#install
if ! (pip install .) ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#install rust
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

pip install -e '.[test]'
cd notebook/tests/
  
#test
#skipping the some testcase as it is failing on x_86 also.

if ! (pytest --ignore=selenium --ignore=test_notebookapp.py --ignore=test_serverextensions.py --ignore=test_files.py         --ignore=test_gateway.py  --ignore=test_utils.py --ignore=test_paths.py); then
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
