#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : foundationdb
# Version       : master
# Source repo   : https://github.com/apple/foundationdb
# Tested on     : UBI 8.4
# Language      : C, C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer's  : Vikas Gupta <vikas.gupta8@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=foundationdb
PACKAGE_URL=https://github.com/apple/foundationdb

yum install -y git wget make maven gcc-c++ openssl-devel tar nano python3 cmake glibc-static libstdc++-static java-1.8.0-openjdk-devel lz4-devel
yum install -y perl-Test-Simple perl-IPC-Cmd perl-Test-Harness perl-Math-BigInt perl-Data-Dumper perl-Pod-Html

dnf -y --disableplugin=subscription-manager install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install -y mono-devel

ln -s /usr/bin/python3 /usr/bin/python
python --version

# ------- Clone and build source -------
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.312.b07-2.el8_5.ppc64le/

export HOME_DIR=/home
cd $HOME_DIR

export GO_VERSION=go1.17.4.linux-ppc64le.tar.gz

wget https://golang.org/dl/$GO_VERSION && \
    tar -C /bin -xf $GO_VERSION && \
    mkdir -p /home/tester/go/src /home/tester/go/bin /home/tester/go/pkg /home/tester/output

rm -rf $GO_VERSION

export PATH=$PATH:/bin/go/bin
export GOPATH=/home/tester/go
export PATH=$GOPATH/bin:$PATH
export GO111MODULE=on

# --------- Installing ninja version v1.4.0 -----------------
echo "--------- Installing ninja version v1.4.0 -----------------"
cd $HOME_DIR
git clone https://github.com/ninja-build/ninja.git
cd ninja
git checkout v1.4.0
./bootstrap.py
cp -r ./ninja /usr/bin/
ninja --version
cd ..

cd $HOME_DIR
git clone --recurse https://github.com/lz4/lz4.git
cd lz4
make 
make install

cd $HOME_DIR
git clone https://github.com/openssl/openssl.git
cd openssl
./config
make 
make install

cd $HOME_DIR
git clone --recurse $PACKAGE_URL

cd $PACKAGE_NAME

mkdir build
cd build

cmake -S .. -D RUN_JUNIT_TESTS=ON -D RUN_JAVA_INTEGRATION_TESTS=ON -G Ninja

ninja -v -j1 all packages strip_targets

ctest -j1 --no-compress-output -T test --output-on-failure
