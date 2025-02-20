#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package        : cockroach
# Version        : v19.1.5
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

# Install all dependencies
yum makecache fast
yum install -y git.ppc64le make.ppc64le gcc-c++.ppc64le autoconf.noarch ncurses-devel.ppc64le wget.ppc64le openssl-devel.ppc64le subscription-manager.ppc64le
subscription-manager repos --enable rhel-7-server-for-power-le-rhscl-rpms
yum makecache fast
yum install -y rh-nodejs8-nodejs.ppc64le

export PATH=$PATH:/opt/rh/rh-nodejs8/root/usr/bin/
npm install yarn --global

COCKROACH_MAKEFILE_PATCH=${COCKROACH_MAKEFILE:-'https://raw.githubusercontent.com/ppc64le/build-scripts/master/c/cockroachdb/Dockerfiles/v19.1.5/patches/cockroach_makefile.patch'}
JEMALLOC_PATCH=${JEMALLOC_PATCH:-'https://raw.githubusercontent.com/ppc64le/build-scripts/master/c/cockroachdb/Dockerfiles/v19.1.5/patches/jemalloc_stats_test.patch'}
ARROW_MEMORY_PATCH=${ARRAOW_MEMORY_PATCH:-'https://raw.githubusercontent.com/ppc64le/build-scripts/master/c/cockroachdb/Dockerfiles/v19.1.5/patches/arrow_memory.patch'}
ROCKSDB_CMAKELISTS=${ROCKSDB_CMAKELISTS:-'https://raw.githubusercontent.com/ppc64le/build-scripts/master/c/cockroachdb/Dockerfiles/v19.1.5/patches/rocksdb_cmakelists.patch'}

CWD=`pwd`

# Compile and install cmake 3.16.1 (since CMake 3.1 or higher is required for the build)
wget https://github.com/Kitware/CMake/releases/download/v3.16.1/cmake-3.16.1.tar.gz
tar -xzf cmake-3.16.1.tar.gz
cd cmake-3.16.1
./bootstrap
make
make install
cd $CWD && rm -rf cmake-3.16.1.tar.gz cmake-3.16.1

# Setup go environment and install go
GOPATH=/root/go
COCKROACH_HOME=$GOPATH/src/github.com/cockroachdb
mkdir -p $COCKROACH_HOME
export GOPATH

curl -O https://dl.google.com/go/go1.12.15.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.12.15.linux-ppc64le.tar.gz
rm -rf go1.12.15.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Clone cockroach and build
cd $COCKROACH_HOME
git clone https://github.com/cockroachdb/cockroach.git
cd cockroach
COCKROACH_VERSION=${1:-v19.1.5}
git checkout -b $COCKROACH_VERSION tags/$COCKROACH_VERSION

# Download the patches
wget ${COCKROACH_MAKEFILE_PATCH}
wget ${ARRAOW_MEMORY_PATCH}
wget ${JEMALLOC_PATCH}
wget ${ROCKSDB_CMAKELISTS}
git apply cockroach_makefile.patch
git apply jemalloc_stats_test.patch
make build
# Execute tests
echo "The tests for the following packages consistently fail:
  pkg/cli
  pkg/util/log
and those for the following packages fail occassionally, but pass when executed independently:
  pkg/server
  pkg/sql/logictest
This result has been confirmed to be in parity with intel though."
export GOMAXPROCS=4
make test TESTFLAGS='-v -count=1' GOFLAGS='-p 1'
