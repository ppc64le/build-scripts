#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : openshift-service-mesh-proxy
# Version       : 1.26
# Source repo   : https://github.com/openshift-service-mesh/proxy
# Tested on     : UBI 9.4
# Language      : C++
# Travis-Check  : FALSE
# Script License: Apache License, Version 2 or later
# Maintainer    : Chandranana
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=proxy
PACKAGE_ORG=openshift-service-mesh
PACKAGE_VERSION=${1:-release-1.26}
PACKAGE_URL=https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}
PATH=$PATH:/usr/local/go/bin
SOURCE_ROOT=$HOME
GO_VERSION=${1:-1.24.0}
GOPATH=$SOURCE_ROOT/go
GOBIN=/usr/local/go/bin
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-21.0.8.0.9-1.el9.ppc64le
PATH=$JAVA_HOME/bin:$PATH
EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk"
ENVOY_STDLIB=libstdc+

yum install -y git wget xz python3.12 libtool automake gcc vim cmake openssl-devel java-21-openjdk-devel openssl libstdc++-static perl lld patch java-11-openjdk-devel python3 ninja-build
ln -s /usr/bin/python3.12 /usr/bin/python

cd $SOURCE_ROOT
git clone $PACKAGE_URL
cd proxy/
git checkout $PACKAGE_VERSION
BAZEL_VERSION=$(cat .bazelversion)

cd $SOURCE_ROOT
mkdir bazel
cd bazel/
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
unzip bazel-${BAZEL_VERSION}-dist.zip
rm -rf bazel-${BAZEL_VERSION}-dist.zip
env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
export PATH=$PATH:$(pwd)/output

#
# Install llvm
#
cd $SOURCE_ROOT
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.6/clang+llvm-18.1.6-powerpc64le-linux-rhel-8.8.tar.xz
tar -xf clang+llvm-18.1.6-powerpc64le-linux-rhel-8.8.tar.xz
rm -rf clang+llvm-18.1.6-powerpc64le-linux-rhel-8.8.tar.xz
                  
export PATH=$SOURCE_ROOT/clang+llvm-18.1.6-powerpc64le-linux-rhel-8.8/bin:$PATH
export CC=$SOURCE_ROOT/clang+llvm-18.1.6-powerpc64le-linux-rhel-8.8/bin/clang
export CXX=$SOURCE_ROOT/clang+llvm-18.1.6-powerpc64le-linux-rhel-8.8/bin/clang++

# Install go
if [ "$( go version | cut -d " " -f3 )" = "go${GO_VERSION}" ]; then
    echo "${GO_VERSION} is already installed"
else
    cd $SOURCE_ROOT
    wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz
    rm -rf /usr/local/go && tar -C /usr/local -xzf go${GO_VERSION}.linux-ppc64le.tar.gz
    which go
    go version
fi

#
# Build proxy
#
cd $SOURCE_ROOT/${PACKAGE_NAME}
source ./ossm/vendor/envoy/bazel/setup_clang.sh $SOURCE_ROOT/clang+llvm-18.1.6-powerpc64le-linux-rhel-8.8/
sed -i "51s/bazel test/bazel test -j 2/g" $SOURCE_ROOT/proxy/ossm/ci/common.sh
# Below commit is tested - tests passed
if ! ./ossm/ci/pre-submit.sh; then
        echo "Build/test execution Fails"
        exit 1
else
        echo "Build & Test execution passed."
fi


