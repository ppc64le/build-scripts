#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package               : infinispan-operator
# Version               : 2.4.3.Final
# Source repo           : https://github.com/infinispan/infinispan-operator
# Tested on             : UBI:9.3
# Language              : Go
# Travis-Check          : True
# Script License        : Apache License 2.0 or later
# Maintainer            : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in non-root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_VERSION=${1:-2.4.3.Final}
PACKAGE_NAME=infinispan-operator
PACKAGE_URL=https://github.com/infinispan/infinispan-operator

yum install -y gcc-c++ make wget git tar patch

#Install go
GO_VERSION=${GO_VERSION:-1.21.0}
wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

wget https://github.com/operator-framework/operator-sdk/releases/download/v1.36.0/operator-sdk_linux_ppc64le
chmod +x operator-sdk_linux_ppc64le
mv operator-sdk_linux_ppc64le /usr/local/bin/operator-sdk
operator-sdk version

# Clone git repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
sed -i 's/errorlint/errorlint --timeout=10m/g' Makefile
go mod vendor

if ! make lint ; then
       echo "------------------$PACKAGE_NAME:Build_fails---------------------"
       echo "$PACKAGE_VERSION $PACKAGE_NAME"
       echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
       exit 1
fi

if ! make test ; then
      echo "------------------$PACKAGE_NAME::Build_and_Test_fails-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Fail|  Build_and_Test_fails"
      exit 2
else
      echo "------------------$PACKAGE_NAME::Build_and_Test_success-------------------------"
      echo "$PACKAGE_URL $PACKAGE_NAME"
      echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Build_and_Test_Success"
      exit 0
fi
