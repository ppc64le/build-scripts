#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : counterfeiter
# Version       : v6.2.2
# Source repo   : https://github.com/maxbrunsfeld/counterfeiter
# Tested on     : UBI 8.5
# Language      : GO
# Travis-Check  : True
# Script License:  Apache License, Version 2 or later
# Maintainer    : Haritha Patchari <haritha.patchari@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=counterfeiter
PACKAGE_VERSION=${1:-v6.2.2}
PACKAGE_URL=https://github.com/maxbrunsfeld/counterfeiter

# Install dependencies
yum install -y make git wget gcc

# Download and install go
wget https://golang.org/dl/go1.17.5.linux-ppc64le.tar.gz
tar -xzf go1.17.5.linux-ppc64le.tar.gz
rm -rf go1.17.5.linux-ppc64le.tar.gz
export GOPATH=`pwd`/gopath
export PATH=`pwd`/go/bin:$GOPATH/bin:$PATH

# Clone the repo and checkout submodules
mkdir -p $GOPATH/src/$PACKAGE_PATH
cd $GOPATH/src/$PACKAGE_PATH
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

go mod tidy

echo "Building $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"

if ! go build -v ./...; then
	echo "------------------$PACKAGE_NAME:build_fails-------------------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
	exit 1
fi
echo "Testing $PACKAGE_PATH$PACKAGE_NAME with $PACKAGE_VERSION"

if ! go test -v ./...; then
	echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
	echo "$PACKAGE_URL $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
	exit 1
else
	echo "------------------$PACKAGE_NAME:install_and_test_success-------------------------"
	echo "$PACKAGE_VERSION $PACKAGE_NAME"
	echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Install_and_Test_Success"
	exit 0
fi


#=== RUN   TestGenerator
#Suite: Generator
#Total: 29 | Focused: 0 | Pending: 0
#=== RUN   TestGenerator/Generator
#=== RUN   TestGenerator/Generator/constructing_a_fake_with_NewFake()/the_target_is_a_nonexistent_package/errors
#=== RUN   TestGenerator/Generator/constructing_a_fake_with_NewFake()/the_target_is_a_package_with_a_nonexistent_interface/errors
#FAIL	github.com/maxbrunsfeld/counterfeiter/v6/generator	3.886s
#=== RUN   TestIntegration
#Suite: integration
#Total: 44 | Focused: 0 | Pending: 0
#=== RUN   TestIntegration/integration
#=== RUN   TestIntegration/integration/round_trip_as_module/generating_a_fake_for_stdlib_interfaces/succeeds
#FAIL	github.com/maxbrunsfeld/counterfeiter/v6/integration	3.480s
#FAIL
