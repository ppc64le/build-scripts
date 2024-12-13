#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : envoy-openssl
# Version       : release/v1.28
# Source repo   : https://github.com/envoyproxy/envoy-openssl/
# Tested on     : RHEL 9.2
# Language      : C++
# Travis-Check  : False
# Script License: Apache License, Version 2 or later
# Maintainer    : Swapnali Pawar <Swapnali.Pawar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=envoy-openssl
PACKAGE_ORG=envoyproxy
SCRIPT_PACKAGE_VERSION=release/v1.28
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}
SCRIPT_PACKAGE_VERSION_WO_LEADING_V="${SCRIPT_PACKAGE_VERSION:1}"

#Install dependencies
yum install -y \
    cmake \
    libatomic \
    libstdc++ \
    libstdc++-static \
    libtool \
    lld \
    patch \
    python3.11-devel \
    python3.11-pip \
    openssl-devel \
    libffi-devel \
    unzip \
    wget \
    zip \
    java-11-openjdk-devel \
    git \
    gcc-c++ \
    xz \
    file \
    binutils \
    rust \
    cargo \
    diffutils \
    ninja-build \
    libxcrypt-compat \
    sudo


#Set environment variables
export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-11-openjdk-*')
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH
scriptdir=$(dirname $(realpath $0))
wdir=/home/envoy
export ENVOY_BIN=$wdir/envoy-openssl/envoy-static
export ENVOY_ZIP=$wdir/envoy-openssl/envoy-static_1.28_UBI9.2.zip
#Find bazel version
wget https://raw.githubusercontent.com/${PACKAGE_ORG}/${PACKAGE_NAME}/${PACKAGE_VERSION}/.bazelversion
BAZEL_VERSION=$(cat .bazelversion)
rm -rf .bazelversion

useradd envoy
sudo -u envoy -- bash <<EOF
set -ex
#Download Envoy source code
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}

# Build and setup bazel
cd $wdir
mkdir bazel
cd bazel
wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
unzip bazel-${BAZEL_VERSION}-dist.zip
rm -rf bazel-${BAZEL_VERSION}-dist.zip
./compile.sh
export PATH=$PATH:$wdir/bazel/output

#Setup clang
cd $wdir
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
tar -xf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
rm -rf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz

#Build Envoy-openssl
cd $wdir/${PACKAGE_NAME}

#Build Envoy-openssl
cd $wdir/${PACKAGE_NAME}
bazel/setup_clang.sh $wdir/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4/
ret=0
bazel build -c opt envoy --config=ppc --config=clang --cxxopt=-fpermissive || ret=$?
if [ -n "$ret" ]; then
    if [ "$ret" -ne 0 ]; then
        echo "FAIL: Build failed."
        exit 1
    fi
fi

#Prepare binary for distribution
cp $wdir/envoy-openssl/bazel-bin/source/exe/envoy-static $ENVOY_BIN
chmod -R 755 $wdir/envoy-openssl
strip -s $ENVOY_BIN
zip $ENVOY_ZIP envoy-static

# Smoke test
$ENVOY_BIN --version || ret=$?
if [ -n "$ret" ]; then
   if [ "$ret" -ne 0 ]; then
        echo "FAIL: Smoke test failed."
        exit 2
   fi
fi

#Run tests (take several hours to execute, hence disabling by default)
#Some tests might fail because of issues with the tests themselves rather than envoy
#bazel test --config=ppc --config=clang --test_timeout=3000 --cxxopt=-fpermissive --define=wasm=disabled //test/... --cache_test_results=no || true
EOF

#Conclude
echo "Build successful!"
echo "Envoy-openssl binary available at [$ENVOY_BIN]"
echo "Redistributable zip available at [$ENVOY_ZIP]"
