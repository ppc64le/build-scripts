#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : bottleneck
# Version       : v1.3.8
# Source repo   : https://github.com/pydata/bottleneck
# Tested on     : UBI: 9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Stuti Wali <Stuti.Wali@ibm.com>
#
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

set -e

# Variables
export PACKAGE_VERSION=${1:-"v1.3.8"}
export PACKAGE_NAME=bottleneck
export PACKAGE_URL=https://github.com/pydata/bottleneck
HOME_DIR=`pwd`

# Install dependencies
yum install -y python3 git gcc gcc-c++ python3-devel python3-setuptools python3-test wget sqlite sqlite-devel libxml2-devel libxslt-devel make cmake

#installation of rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="$HOME/.cargo/bin:$PATH"
source ~/.bashrc
rustc --version

pip3 install --upgrade setuptools virtualenv mock ipython_genutils pytest traitlets numpy

cd $HOME_DIR
# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
export TOXENV=py39
virtualenv -p python3 --system-site-packages env2 
/bin/bash -c "source env2/bin/activate"
pip3 install tox 
PATH=$PATH:/usr/local/bin/

# Build package
if !(python3 setup.py install) ; then
    echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Run test cases
if !(tox); then
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
