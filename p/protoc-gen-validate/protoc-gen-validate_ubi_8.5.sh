#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : protoc-gen-validate
# Version       : v0.6.6
# Source repo   : https://github.com/envoyproxy/protoc-gen-validate.git
# Tested on     : ubi 8.5
# Language      : go
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer    : Sachin K {sachin.kakatkar@ibm.com}
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#Run the script:./protoc-gen-validate_ubi_8.5.sh v0.6.6(version_to_test)
PACKAGE_NAME=protoc-gen-validate
PACKAGE_VERSION=${1:-v0.6.6}
GO_VERSION=1.17.1
PACKAGE_URL=https://github.com/envoyproxy/protoc-gen-validate.git
dnf copr enable vbatts/bazel -y
dnf install git wget sudo make gcc unzip bazel4 python3-devel python3 diffutils.ppc64le gcc-c++ automake autoconf libtool -y
pip3 install flake8 isort
mkdir -p /home/tester/output
cd /home/tester

wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
rm -rf /home/tester/go && tar -C /home/tester -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
export  GO111MODULE=on
mkdir -p $GOPATH/src/github.com/envoyproxy
cd $GOPATH/src/github.com/envoyproxy
ln -sf $(which python3) /bin/python
rm -rf $PACKAGE_NAME

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

if ! git clone $PACKAGE_URL $PACKAGE_NAME; then
        echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/clone_fails
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Clone_Fails" > /home/tester/output/version_tracker
        exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

sed -i 's,https://zlib.net/zlib-1.2.11.tar.gz,https://webwerks.dl.sourceforge.net/project/libpng/zlib/1.2.11/zlib-1.2.11.tar.gz,g' bazel/repositories.bzl

if ! (make bazel); then
        INSTALL_SUCCESS="false"
        else
        INSTALL_SUCCESS="true"
fi

if ! (make example-workspace); then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME" > /home/tester/output/test_fails
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails" > /home/tester/output/version_tracker
        exit 1
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /home/tester/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /home/tester/output/version_tracker
        exit 0
fi

#Other make target options:build lint harness bazel-tests testcases gazelle check-generated
