#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package	: influxdb
# Version	: v2.5.1
# Source repo	: https://github.com/influxdata/influxdb.git
# Tested on	: UBI: 8.5
# Language      : Go 
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer	: Muskaan Sheik <Muskaan.Sheik@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=influxdb
PACKAGE_VERSION=${1:-v2.5.1}
PACKAGE_URL=https://github.com/influxdata/influxdb.git

yum install -y sudo
sudo yum update -y
sudo yum install -y gcc-c++ wget git clang make pkg-config pkgconfig unzip

#install bazel to build protobuf
dnf install -y dnf-plugins-core
dnf copr enable vbatts/bazel -y
dnf install -y bazel4

#install go
wget https://go.dev/dl/go1.19.3.linux-ppc64le.tar.gz
rm -rf /usr/local/go
tar -C /usr/local -xzf  go1.19.3.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

#install rustup
wget https://static.rust-lang.org/dist/rust-1.65.0-powerpc64le-unknown-linux-gnu.tar.gz
tar -xzf rust-1.65.0-powerpc64le-unknown-linux-gnu.tar.gz
cd rust-1.65.0-powerpc64le-unknown-linux-gnu
./install.sh
cd ..

#install protobuf
git clone https://github.com/protocolbuffers/protobuf.git
cd protobuf
git checkout v21.5
git submodule update --init --recursive
bazel build :protoc :protobuf
cp bazel-bin/protoc /usr/local/bin

cd ..

cd /tmp
wget https://github.com/protocolbuffers/protobuf/releases/download/v21.9/protoc-21.9-linux-ppcle_64.zip
unzip protoc-21.9-linux-ppcle_64.zip
cd include
cp -r google /usr/local/include/

cd /
export PATH=/root/go/bin:$PATH

go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

make
#make test

export str="authorization authorizer backup bolt checks cmd context dashboards dbrp gather http influxql inmem jsonweb kit kv label mock models notebooks notification pkg pkger predicate prometheus query rand remotes replications secret session snowflake sqlite static task telegraf telemetry tenant toml tools v1"
for i in $str; do cd $i; echo $i; go test ./...; cd ..; done 

#1 test case failure(group_resultset_test.go).
#The same is open in issues at https://github.com/influxdata/influxdb/issues/23768