#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : influxdb
# Version       : v2.7.6
# Source repo   : https://github.com/influxdata/influxdb
# Tested on     : UBI:9.3
# Language      : Go
# Travis-Check  : True
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
PACKAGE_NAME=influxdb
PACKAGE_VERSION=${1:-v2.7.6}
PACKAGE_URL=https://github.com/influxdata/influxdb

yum install -y gcc gcc-c++ python3 python3-devel git wget sudo make autoconf automake zlib-devel bzip2 bzip2-devel xz-devel curl-devel openssl-devel
yum install -y ncurses-devel diffutils libtool json-c.ppc64le elfutils-libelf.ppc64le cmake patch libcap

#install protbuf
git clone https://github.com/protocolbuffers/protobuf
cd protobuf
git checkout v3.17.3
./autogen.sh
./configure
make
make install
cd ..

export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
#install protoc-c
git clone https://github.com/protobuf-c/protobuf-c
cd protobuf-c
git checkout v1.4.0
./autogen.sh
./configure
make
make install
cd ..

#install rustc
curl https://sh.rustup.rs -sSf | sh -s -- -y
PATH="$HOME/.cargo/bin:$PATH"
source $HOME/.cargo/env
rustc --version

GO_VERSION=1.21.6
wget https://golang.org/dl/go$GO_VERSION.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go$GO_VERSION.linux-ppc64le.tar.gz
rm -rf go$GO_VERSION.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! make; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

export str="authorization authorizer backup bolt checks cmd context dashboards dbrp gather http influxql inmem jsonweb kit kv label mock models notebooks notification pkg pkger predicate prometheus query rand remotes replications secret session snowflake sqlite static task telegraf telemetry tenant toml tools v1"

if ! go test ./... -timeout=30m; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
