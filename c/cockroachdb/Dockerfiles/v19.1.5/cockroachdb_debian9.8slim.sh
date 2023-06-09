# ----------------------------------------------------------------------------
#
# Package        : cockroach
# Version        : v19.1.5
# Source repo    : https://github.com/cockroachdb/cockroach
# Tested on      : debian 9.8-slim
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
apt-get update
apt-get install -y git make curl g++ autoconf gnupg2 cmake libncurses5-dev flex bison
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
export NVM_DIR="/root/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install v8.16.1
npm install yarn --global

CWD=`pwd`

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
git checkout -b v19.1.5 tags/v19.1.5
# This step assumes that you have already copied the patches directory as a sibbling of this script
cp $CWD/patches/* .
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
