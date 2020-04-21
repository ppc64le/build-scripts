# ----------------------------------------------------------------------------
#
# Package        : istio
# Version        : maistra-1.1
# Source repo    : https://github.com/Maistra/proxy.git
# Tested on      : RHEL 7.6
# Script License : Apache License, Version 2 or later
# Maintainer     : Siddhesh Ghadi <Siddhesh.Ghadi@ibm.com>
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
BUILD_VERSION=maistra-1.1

#Install libraries
yum update -y
yum install -y devtoolset-7*
source scl_source enable devtoolset-7
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum install -y libtool patch aspell-en automake autoconf make curl unzip binutils-devel
yum install -y wget tar git cmake3 zip
ln -sf /usr/bin/cmake3 /usr/bin/cmake
wget https://copr.fedorainfracloud.org/coprs/vbatts/bazel/repo/epel-7/vbatts-bazel-epel-7.repo -P /etc/yum.repos.d/
yum install -y bazel
java --version


#Install Go
curl -O https://dl.google.com/go/go1.13.5.linux-ppc64le.tar.gz
tar -C /usr/local -xzf go1.13.5.linux-ppc64le.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GOPATH=/root/go
export GOBIN=/usr/local/go/bin
rm -rf go1.13.5.linux-ppc64le.tar.gz

mkdir ~/istio_build/
export SOURCE_ROOT=~/istio_build/
cd $SOURCE_ROOT

#Build ninja
git clone git://github.com/ninja-build/ninja.git && cd ninja
git checkout v1.8.2
./configure.py --bootstrap
export PATH=/usr/local/bin:$PATH
ln -sf $SOURCE_ROOT/ninja/ninja /usr/local/bin/ninja
ninja --version


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

#Build Openssl
cd $SOURCE_ROOT
yum install -y git perl-core
git clone https://github.com/openssl/openssl
cd openssl/
git checkout OpenSSL_1_1_1-stable
./config
make
make install
cp libcrypto.so.1.1 libssl.so.1.1 /usr/lib64

#Build Maistra/proxy
cd $SOURCE_ROOT
git clone https://github.com/Maistra/proxy
cd proxy/
git checkout $BUILD_VERSION
git apply $WORKDIR/patches/proxy.patch
mkdir patches 
cd patches
cp $WORKDIR/patches/wee8_genrule_cmd.patch .
cd ..
touch patches/BUILD
export BAZEL_BUILD_ARGS="--host_javabase=@local_jdk//:jdk --verbose_failures --copt \"-DENVOY_IGNORE_GLIBCXX_USE_CXX11_ABI_ERROR=1\" --cxxopt=-Wimplicit-fallthrough=0"
make -f Makefile.core.mk BUILD_WITH_CONTAINER=0 build
#Run container in privileged mode if running tests.
make BAZEL_ENVOY_PATH=$SOURCE_ROOT/proxy/bazel-bin/src/envoy/envoy BAZEL_BUILD_ARGS="--host_javabase=@local_jdk//:jdk --test_env=ENVOY_IP_TEST_VERSIONS=v4only" test

