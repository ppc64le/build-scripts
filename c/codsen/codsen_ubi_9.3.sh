#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : codsen
# Version          : util-nonempty@5.0.16
# Source repo      : https://github.com/codsen/codsen
# Tested on	   : UBI:9.3
# Language         : Javascript,Typescript
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : vinodk99 <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=codsen
PACKAGE_VERSION=${1:-util-nonempty@5.0.16}
PACKAGE_URL=https://github.com/codsen/codsen

yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official

yum install -y git gcc gcc-c++ libffi make libpng-devel patch automake openssl-devel libtool cmake binutils lld clang perl perl-IPC-Cmd llvm wget cargo

#Install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
source ~/.cargo/env

#Install go
wget https://go.dev/dl/go1.22.1.linux-ppc64le.tar.gz
tar -C  /usr/local -xf go1.22.1.linux-ppc64le.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

#Install node
export NODE_VERSION=${NODE_VERSION:-20}
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source "$HOME"/.bashrc
echo "installing nodejs $NODE_VERSION"
nvm install "$NODE_VERSION" >/dev/null
nvm use $NODE_VERSION
npm install -g pnpm yarn

go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28.0
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2.0

#install protoc
PROTOBUF_VERSION=3.15.0
wget https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOBUF_VERSION/protoc-$PROTOBUF_VERSION-linux-ppcle_64.zip
unzip -u protoc-$PROTOBUF_VERSION-linux-ppcle_64.zip

export PROTOC=/home/testuser/bin/
export PATH=$PROTOC:$PATH
cp -r include/* /usr/local/include
cp bin/protoc /usr/local/bin

#Install canproto
git clone -b master https://github.com/capnproto/capnproto.git
cd capnproto/c++
autoreconf -i
./configure
make -j$(nproc)
make install
cd ../..

#install and appy patch for turborepo
git clone https://github.com/vercel/turborepo       
cd turborepo
git checkout v2.3.3
wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/t/turborepo/turborepo_2.3.3.patch
patch -p1 < turborepo_2.3.3.patch
pnpm install

export PROTOC=/usr/local/bin/protoc
export PROTOC_INCLUDE=/usr/local/include

cargo build -p turbo --release

export PATH=$PATH:/turborepo/target/release
turbo --version
cd ..

git clone $PACKAGE_URL 
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

if ! npm install ; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
export TURBO_BINARY_PATH=/turborepo/target/release/turbo
npm run build

if ! turbo run unit; then
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