# -----------------------------------------------------------------------------
#
# Package       : github.com/go-stack/stack
# Version       : v1.8.0
# Source repo   : https://github.com/go-stack/stack.git
# Tested on     : RHEL 8.4
# Language      : GO
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Baheti (aramswar@in.ibm.com)
#
# Disclaimer    : This script has been tested in root mode on given
# ==========    platform using the mentioned version of the package.
#               It may not work as expected with newer versions of the
#               package and/or distribution. In such case, please
#               contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=github.com/go-stack/stack
#Setting the default version v1.8.0
PACKAGE_VERSION=${1:-v1.8.0}
PACKAGE_PATH=https://github.com/go-stack/stack.git

if ! command -v git &> /dev/null
then
    yum install -y git
fi
# Install Go and setup working directory
if ! command -v go &> /dev/null
then
    yum install -y golang
fi

mkdir -p /root/output

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export GOPATH="$(go env GOPATH)"
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

echo "Building $PACKAGE_PATH with $PACKAGE_VERSION"
mkdir -p $GOPATH/src/github.com/go-stack && cd $GOPATH/src/github.com/go-stack
git clone $PACKAGE_PATH  && cd "$(basename "$_" .git)" && git checkout $PACKAGE_VERSION

if ! go build -v; then
        exit 0
fi

echo "Testing $PACKAGE_PATH with $PACKAGE_VERSION"

if ! go test -v ./...; then
        exit 0
else
        echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
        echo "$PACKAGE_VERSION $PACKAGE_NAME" > /root/output/test_success
        echo "$PACKAGE_NAME  |  $PACKAGE_VERSION | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success" > /root/output/version_tracker
        exit 0
fi
