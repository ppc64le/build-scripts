#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : nbformat
# Version          : v5.9.2
# Source repo      : https://github.com/jupyter/nbformat
# Tested on        : UBI 8.7
# Language         : Jupyter Notebook,Python
# Ci-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=nbformat
PACKAGE_VERSION=${1:-v5.9.2}
PACKAGE_URL=https://github.com/jupyter/nbformat
HOME_DIR=${PWD}

yum install -y git python3.11 python3.11-devel python3.11-pip openssl-devel openssl gcc-c++

# Install pip and activate venv
python3 -m ensurepip --upgrade
export PATH=$PATH:/usr/local/bin

#install Rustc
curl https://sh.rustup.rs -sSf | sh -s -- -y
PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env
rustc --version

pip3 install hatch

# Clone package repository
cd $HOME_DIR
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# Install
if !  python3 -m pip install -e .; then
        echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
fi

# Test
python3 -m pip install nbformat[test]
if ! pytest ; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
        exit 2
else
        echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
        exit 0
fi

