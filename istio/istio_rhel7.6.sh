# ----------------------------------------------------------------------------
#
# Package        : istio
# Version        : 1.4.3
# Source repo    : https://github.com/istio/istio.git
# Tested on      : RHEL 7.6
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

WORKDIR=`pwd`

# Install all dependencies
yum install -y devtoolset-7*
source scl_source enable devtoolset-7
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y libtool patch aspell-en automake autoconf make curl unzip binutils-devel
yum install -y wget tar git cmake3 zip
ln -sf /usr/bin/cmake3 /usr/bin/cmake
wget https://copr.fedorainfracloud.org/coprs/vbatts/bazel/repo/epel-7/vbatts-bazel-epel-7.repo -P /etc/yum.repos.d/
yum install -y bazel

yum install -y java-1.8.0-openjdk-devel
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-1.8.0-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH

curl -O https://dl.google.com/go/go1.13.5.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.13.5.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
export GOBIN=/usr/local/go/bin
rm -rf go1.13.5.linux-ppc64le.tar.gz

mkdir ~/istio_build/
export SOURCE_ROOT=~/istio_build/

# Compile and install ninja
cd $SOURCE_ROOT
git clone git://github.com/ninja-build/ninja.git && cd ninja
git checkout v1.8.2
./configure.py --bootstrap
export PATH=/usr/local/bin:$PATH
ln -sf $SOURCE_ROOT/ninja/ninja /usr/local/bin/ninja
ninja --version

# Compile and install gn
cd $SOURCE_ROOT
git clone https://gn.googlesource.com/gn
cd gn
git checkout 992e927e217baa8a74e6e2c5d7417cb65cf24824
export CC=/opt/rh/devtoolset-7/root/usr/bin/gcc
export CXX=/opt/rh/devtoolset-7/root/usr/bin/g++
python build/gen.py
ninja -C out
cd out/
export PATH=$PATH:`pwd`

# Clone istio-proxy and build
cd $SOURCE_ROOT
git clone https://github.com/istio/proxy.git
cd proxy
git checkout 1.4.3
cp $WORKDIR/patches/proxy_src_1.4.3.patch .
git apply proxy_src_1.4.3.patch
mkdir patches
cp $WORKDIR/patches/wee8_genrule_cmd.patch patches/
touch patches/BUILD
export BAZEL_BUILD_ARGS="--host_javabase=@local_jdk//:jdk --verbose_failures --copt \"-DENVOY_IGNORE_GLIBCXX_USE_CXX11_ABI_ERROR=1\" --cxxopt=-Wimplicit-fallthrough=0"
make -f Makefile.core.mk BUILD_WITH_CONTAINER=0 build

# Clone istio, build and execute unit tests
mkdir $GOPATH
cd $GOPATH
go get -u github.com/jstemmer/go-junit-report
mkdir -p $GOPATH/src/istio.io && cd $GOPATH/src/istio.io
ln -s $SOURCE_ROOT/proxy ./proxy
git clone https://github.com/istio/istio.git
cd istio
git checkout 1.4.3
git cherry-pick f0a038d58fade8d1730e1e108751e10b6502083b
make -f Makefile.core.mk BUILD_WITH_CONTAINER=0 USE_LOCAL_PROXY=1 build
make -f Makefile.core.mk test

