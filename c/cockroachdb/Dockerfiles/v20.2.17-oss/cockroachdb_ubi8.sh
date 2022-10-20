# ----------------------------------------------------------------------------
#
# Package        : cockroach
# Version        : v20.2.17
# Source repo    : https://github.com/cockroachdb/cockroach
# Tested on      : UBI 8
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

CWD=`pwd`

# Install all dependencies
dnf -y --disableplugin=subscription-manager install \
        http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-2.el8.noarch.rpm \
        http://mirror.centos.org/centos/8/BaseOS/ppc64le/os/Packages/centos-linux-repos-8-2.el8.noarch.rpm \
        https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

yum install -y git cmake make gcc-c++ autoconf ncurses-devel.ppc64le wget.ppc64le openssl-devel.ppc64le diffutils procps-ng

cd $HOME

set -eu

# Install nodejs
NODE_VERSION=v12.18.2
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
curl -O https://dl.google.com/go/go1.13.5.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.13.5.linux-ppc64le.tar.gz
rm -rf go1.13.5.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Clone cockroach and build
COCKROACH_VERSION=v20.2.17
cd $COCKROACH_HOME
git clone https://github.com/cockroachdb/cockroach.git
cd cockroach
git checkout $COCKROACH_VERSION
# Patch out thread stack dump feature for ppc64le as a workaround
# Ref: https://github.com/cockroachdb/cockroach/issues/62979
sed -i '/add_definitions(-DOS_LINUX)/d' c-deps/libroach/CMakeLists.txt
sed -i 's/thread stacks only available on Linux\/Glibc/thread stacks feature unsupported for ppc64le/g' c-deps/libroach/stack_trace.cc
make buildoss

# Execute tests
echo "The tests for following packages consistently fail:
  pkg/ccl/logictestccl
  pkg/geo
  pkg/geo/geogfn
  pkg/geo/geographiclib
  pkg/geo/geoindex
  pkg/geo/geomfn
  pkg/sql
  pkg/sql/logictest
  pkg/sql/opt/exec/execbuilder
  pkg/sql/sem/tree
  pkg/sql/sem/tree/eval_test
  pkg/util/log
Please refer the README for details on why those are ignored."

export GOMAXPROCS=4
make test TESTFLAGS='-v -count=1' GOFLAGS='-p 1' IGNORE_GOVERS=1

