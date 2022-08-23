# ----------------------------------------------------------------------------
#
# Package               : protobuf
# Version               : v1.3.2
# Source repo           : https://github.com/gogo/protobuf
# Tested on             : UBI 8.3
# Language              : Java,C++
# Travis-Check          : True
# Script License        : Apache License, Version 2 or later
# Passing Arguments     : Passing Arguments: 1.Version of package,
# Script License        : Apache License, Version 2 or later
# Maintainer            : Priya Seth<sethp@us.ibm.com> Adilhusain Shaikh <Adilhusain.Shaikh@ibm.com>
#
# Disclaimer            : This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

PACKAGE_NAME="protobuf"
PACKAGE_VERSION=${1:-v1.3.2}
PACKAGE_URL="https://github.com/gogo/protobuf"
OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

export GO_VERSION=${GO_VERSION:-1.15}
export GOROOT=${GOROOT:-/usr/local/go}
export GOPATH=${GOPATH:-$HOME/go}
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
#exporting  protocolbuffers/protobuf  version which is a dependency  for this PKG
export PROTOC_VERSION=${PROTOC_VERSION:-3.14.0}


# steps to clean up the PKG installation
if  [ "$1" = "clean" ]; then
    rm -rf /usr/local/go
    rm -rf $HOME/go
    rm -rf $HOME/$PACKAGE_NAME
    exit 0;
fi

echo "installing dependencies from system repo..."
dnf install -y git wget  make unzip gcc-c++ > /dev/null

echo "installing go $GO_VERSION"
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /usr/local/ -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -f go$GO_VERSION.linux-ppc64le.tar.gz

echo "installing protocol buffer $PROTOC_VERSION"
case $PROTOC_VERSION in
    3*)
        wget https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-ppcle_64.zip
        unzip -d /usr protoc-${PROTOC_VERSION}-linux-ppcle_64.zip
    ;;
    2*)
        wget https://github.com/google/protobuf/releases/download/v$PROTOC_VERSION/protobuf-$PROTOC_VERSION.tar.gz
        tar -xzf protobuf-$PROTOC_VERSION.tar.gz
        cd protobuf-$PROTOC_VERSION
        ./configure --prefix="/usr" --libdir="/lib64"
        make && make install
        cd ..
    ;;
    *)
        echo "unknown protoc version!"
        exit 1
    ;;
esac

# deleting protocol buffers source
rm -rf proto*

mkdir -p $GOPATH/src/github.com/gogo
cd  $GOPATH/src/github.com/gogo
git clone --quiet $PACKAGE_URL $PACKAGE_NAME || exit 1
echo "cloning complete..."
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION || exit 1
echo "building $PACKAGE_NAME $PACKAGE_VERSION"
export GO111MODULE=on

#Build and test
go get -v -t ./...

if ! make  buildserverall ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi



if ! make testall  ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_success_but_test_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi