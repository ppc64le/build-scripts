#!/bin/bash -e
#
# -----------------------------------------------------------------------------
#
# Package       : gunicorn
# Version       : 23.0.0
# Source repo   : https://github.com/benoitc/gunicorn
# Tested on     : UBI 9.3
# Language      : c
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=gunicorn
PACKAGE_VERSION=${1:-23.0.0}
PACKAGE_URL=https://github.com/benoitc/gunicorn
PACKAGE_DIR=gunicorn

yum install -y git gcc-toolset-13 gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ make python3 python3-devel python3-pip openssl-devel 
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
#install rustc
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
rustc --version

# Clone the repo
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
pip3 install pytest-cov eventlet gevent

# Install the package
if ! python3 -m pip install -e .; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run tests
if ! pytest; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
    echo "$PACKAGE_VERSION $PACKAGE_NAME"
    echo "$PACKAGE_NAME  | $PACKAGE_VERSION | GitHub  | Pass |  Install_and_Test_Success"
    exit 0
fi
