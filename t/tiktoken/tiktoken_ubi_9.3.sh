#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tiktoken
# Version       : 0.6.0
# Source repo   : https://github.com/openai/tiktoken.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=tiktoken
PACKAGE_VERSION=${1:-"0.6.0"}
PACKAGE_URL=https://github.com/openai/tiktoken.git
PYTHON_VERSION=${PYTHON_VERSION:-"3.11"}


yum install -y git libffi-devel gcc python${PYTHON_VERSION}-devel python${PYTHON_VERSION}-pip python${PYTHON_VERSION}-setuptools
python${PYTHON_VERSION} -m pip install pytest hypothesis

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

source $HOME/.cargo/env
export PATH="$HOME/.cargo/bin:$PATH"

if [ -z $PACKAGE_SOURCE_DIR ]; then
  git clone $PACKAGE_URL -b $PACKAGE_VERSION
  cd $PACKAGE_NAME
else
  cd $PACKAGE_SOURCE_DIR
fi

git checkout $PACKAGE_VERSION

git submodule update --init --recursive

if ! python${PYTHON_VERSION} -m pip install -v -e .; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run test cases
if ! python${PYTHON_VERSION} -m pytest; then
    echo "------------------$PACKAGE_NAME:build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:build_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Build_and_Test_Success"
    exit 0
fi
