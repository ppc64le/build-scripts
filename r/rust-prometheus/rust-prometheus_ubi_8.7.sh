#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : rust-prometheus
# Version       : v0.13.3
# Source repo   : https://github.com/tikv/rust-prometheus
# Tested on     : UBI 8.7
# Language      : Rust
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=rust-prometheus
PACKAGE_VERSION=${1:-v0.13.3}
PACKAGE_URL=https://github.com/tikv/rust-prometheus

yum install git wget gcc gcc-c++ make -y

#Install rustc
curl https://sh.rustup.rs -sSf | sh -s -- -y 
source ~/.cargo/env

git clone $PACKAGE_URL 
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! cargo build ;  then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

if ! cargo test ; then
    echo "------------------$PACKAGE_NAME:Build_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
