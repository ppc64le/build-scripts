# ----------------------------------------------------------------------------
#
# Package        : cockroach
# Version        : v19.2.2
# Source repo    : https://github.com/cockroachdb/cockroach
# Tested on      : UBI 7.6, RHEL 7.6
# Script License : Apache License, Version 2 or later
# Maintainer     : Amit Sadaphule <amits2@us.ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash

# Install all dependencies
yum makecache fast
yum install -y git.ppc64le make.ppc64le gcc-c++.ppc64le autoconf.noarch ncurses-devel.ppc64le wget.ppc64le openssl-devel.ppc64le subscription-manager.ppc64le
subscription-manager repos --enable rhel-7-server-for-power-le-rhscl-rpms
yum makecache fast
yum install -y rh-nodejs12-nodejs.ppc64le

export PATH=$PATH:/opt/rh/rh-nodejs12/root/usr/bin/
npm install yarn --global

CWD=`pwd`

# Compile and install cmake 3.16.1 (since CMake 3.1 or higher is required for the build)
wget https://github.com/Kitware/CMake/releases/download/v3.16.1/cmake-3.16.1.tar.gz
tar -xzf cmake-3.16.1.tar.gz
cd cmake-3.16.1
./bootstrap
make
make install
cd $CWD && rm -rf cmake-3.16.1.tar.gz cmake-3.16.1

# Setup go environment ans install go
GOPATH=/root/go
COCKROACH_HOME=$GOPATH/src/github.com/cockroachdb
mkdir -p $COCKROACH_HOME
export GOPATH

curl -O https://dl.google.com/go/go1.13.5.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.13.5.linux-ppc64le.tar.gz
rm -rf go1.13.5.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Clone cockroach and build
cd $COCKROACH_HOME
git clone https://github.com/cockroachdb/cockroach.git
cd cockroach
git checkout -b v19.2.2 tags/v19.2.2
# This step assumes that you have already copied the patches directory as a sibbling of this script
cp $CWD/patches/* .
git apply cockroach_makefile.patch
git apply jemalloc_stats_test.patch
make build
# Execute tests
echo "The tests for one or more of the following packages may fail:
  pkg/ccl/xx
  pkg/cli
  pkg/storage/engine
  pkg/sql/logictest
But those failing tests pass when we execute them independently.
This result has been confirmed to be in parity with intel though."
export GOMAXPROCS=4
make test TESTFLAGS='-v -count=1' GOFLAGS='-p 1'

