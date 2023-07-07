#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package        : cockroach
# Version        : v22.1.5
# Source repo    : https://github.com/cockroachdb/cockroach
# Tested on      : UBI 8.5
# Language       : GO
# Travis-Check   : False
# Script License : Apache License, Version 2 or later
# Maintainer     : Ambuj Kumar <Ambuj.Kumar3@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
CWD=`pwd`

# Install all dependencies
yum install -y git cmake make gcc-c++ autoconf ncurses-devel libarchive curl \
    wget openssl-devel diffutils procps-ng libarchive xz python2

yum install -y \
    http://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/Packages/bison-3.0.4-10.el8.ppc64le.rpm \
    http://rpmfind.net/linux/epel/8/Everything/ppc64le/Packages/c/ccache-3.7.7-1.el8.ppc64le.rpm

cd $HOME

# Install nodejs
NODE_VERSION=v16.13.0
DISTRO=linux-ppc64le
wget https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-$DISTRO.tar.gz
tar -xzf node-$NODE_VERSION-$DISTRO.tar.gz
export PATH=$HOME/node-$NODE_VERSION-$DISTRO/bin:$PATH

npm install yarn --global

cd $HOME

# Setup go environment and install go
GOPATH=$HOME/go
COCKROACH_HOME=$GOPATH/src/github.com/cockroachdb
mkdir -p $COCKROACH_HOME
export GOPATH

curl -O https://dl.google.com/go/go1.17.11.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.17.11.linux-ppc64le.tar.gz
rm -rf go1.17.11.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Clone cockroach and build
COCKROACH_VERSION=v22.1.5
cd $COCKROACH_HOME
git clone https://github.com/cockroachdb/cockroach.git
cd cockroach
git checkout $COCKROACH_VERSION

cp $CWD/patches/* .
git apply webpack_vendor.patch
make buildoss

# Execute tests
echo "The tests for following packages consistently fail:
  pkg/ccl/logictestccl
  pkg/geo
  pkg/geo/geogfn
  pkg/geo/geoindex
  pkg/geo/geomfn
  pkg/sql
  pkg/sql/logictest
  pkg/sql/opt/exec/execbuilder
  pkg/sql/opt/memo
  pkg/sql/sem/tree
  pkg/sql/sem/tree/eval_test
  pkg/util/log/logcrash
Please refer the README for details on why those are ignored."

make test TESTFLAGS='-v -count=1' GOFLAGS='-p 1' IGNORE_GOVERS=1
#make test
