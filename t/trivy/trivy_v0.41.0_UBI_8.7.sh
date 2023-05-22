#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : trivy
# Version          : v0.41.0
# Source repo      : https://github.com/aquasecurity/trivy
# Tested on        : UBI 8.7
# Language         : GO
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=trivy
PACKAGE_VERSION=${1:-v0.41.0}
PACKAGE_URL=https://github.com/aquasecurity/trivy

export GOPATH=/root/trivy/go
export GOROOT=/usr/local/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
yum install -y git wget gcc python38

#install go

GO_VERSION=1.20.1
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -rf go$GO_VERSION.linux-ppc64le.tar.gz

mkdir -p $GOPATH/src/github.com/aquasecurity
cd $GOPATH/src/github.com/aquasecurity
git clone https://github.com/magefile/mage
cd mage
go run bootstrap.go
git clone https://github.com/aquasecurity/trivy.git


#build tinygo

yum install -y gcc make cmake clang gcc-c++
git clone --recursive https://github.com/tinygo-org/tinygo.git

wget https://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/Packages/ninja-build-1.8.2-1.el8.ppc64le.rpm
yum install -y  ninja-build-1.8.2-1.el8.ppc64le.rpm
cd tinygo
make llvm-source
make llvm-build

make wasi-libc
make binaryen
make

#build and test trivy

cd ..
cd trivy
git checkout $PACKAGE_VERSION
go mod tidy
export PATH=/root/trivy/go/src/github.com/aquasecurity/mage/tinygo/build:$PATH


if ! mage build; then
        echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
        exit 1
fi

if ! mage test:unit; then
        echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
        exit 2
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
        exit 0
fi
