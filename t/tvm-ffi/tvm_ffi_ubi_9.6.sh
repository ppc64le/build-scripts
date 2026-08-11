#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : tvm-ffi
# Version          : v0.1.9
# Source repo      : https://github.com/apache/tvm-ffi.git
# Tested on        : UBI:9.6
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com> 
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash
set -ex

# Variables
PACKAGE_NAME=tvm-ffi
PACKAGE_VERSION=${1:-"v0.1.9"}
PACKAGE_URL=https://github.com/apache/tvm-ffi.git
PACKAGE_DIR=tvm-ffi

# Install dependencies
yum install -y git gcc gcc-c++ make cmake ninja-build python3.11 python3.11-devel python3.11-pip python3.11-setuptools

# Upgrade pip and install build/test tools
python3.11 -m pip install --upgrade pip setuptools wheel pytest numpy

# Clone repository
git clone $PACKAGE_URL
cd $PACKAGE_DIR

git checkout $PACKAGE_VERSION

git submodule update --init --recursive

# Install package
if ! python3.11 -m pip install -v .; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_Fails"
    exit 1
fi


# Run tests if available
if [ -d "tests" ]; then
    if ! python3.11 -m pytest -v; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail | Install_success_but_test_Fails"
        exit 2
    fi
fi

echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Pass | Both_Install_and_Test_Success"
exit 0