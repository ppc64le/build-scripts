# ----------------------------------------------------------------------------
#
# Package        : cockroach
# Version        : v19.2.10
# Source repo    : https://github.com/cockroachdb/cockroach
# Tested on      : UBI 8
# Script License : Apache License, Version 2 or later
# Maintainer     : Amol Patil <amol.patil2@ibm.com>
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
yum install -y git.ppc64le make.ppc64le gcc-c++.ppc64le autoconf.noarch ncurses-devel.ppc64le wget.ppc64le openssl-devel.ppc64le subscription-manager.ppc64le diffutils
subscription-manager repos --enable rhel-7-server-for-power-le-rhscl-rpms
yum makecache fast

CWD=`pwd`

# Install nodejs
NODE_VERSION=v12.18.2
DISTRO=linux-ppc64le 
wget "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-$DISTRO.tar.gz"
tar -xzf node-$NODE_VERSION-$DISTRO.tar.gz
export PATH=$CWD/node-$NODE_VERSION-$DISTRO/bin:$PATH 
npm install yarn --global

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

curl -O https://dl.google.com/go/go1.13.5.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.13.5.linux-ppc64le.tar.gz
rm -rf go1.13.5.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Clone cockroach and build
COCKROACH_VERSION=v19.2.10
cd $COCKROACH_HOME
git clone https://github.com/cockroachdb/cockroach.git
cd cockroach
git checkout COCKROACH_VERSION 
# This step assumes that you have already copied the patches directory as a sibbling of this script
cp $CWD/patches/* .
git apply cockroach_makefile.patch
git apply jemalloc_stats_test.patch
make buildoss | tee build_logs.txt

# Execute tests
echo "The tests for following packages may fail:
  pkg/sql/
But those failing tests pass when we execute them independently."

export GOMAXPROCS=4
make test TESTFLAGS='-v -count=1' GOFLAGS='-p 1' IGNORE_GOVERS=1 | tee test_logs.txt

# create tarball 
tar czf cockroachdb_ubi8.tar.gz cockroachoss build_logs.txt test_logs.txt

