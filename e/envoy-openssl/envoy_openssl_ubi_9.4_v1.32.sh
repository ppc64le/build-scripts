#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : envoy-openssl
# Version       : release/v1.32
# Source repo   : https://github.com/envoyproxy/envoy-openssl/
# Tested on     : RHEL 9.4
# Language      : C++
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Anurag Chitrakar <Anurag.Chitrakar@ibm.com>
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
SCRIPT_PACKAGE_VERSION=release/v1.32
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
    gcc-toolset-12-libatomic-devel \
    python3-pip \
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
#echo "envoy  ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers > /dev/null
sudo -u envoy -- bash <<EOF
set -ex

#Download Envoy source code
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}

#Build and setup bazel
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
tar -xvf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz
export PATH=/home/envoy/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4/bin:$PATH
rm -rf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4.tar.xz

#installing cargo and cross
curl https://sh.rustup.rs -sSf | sh -s -- -y && source ~/.cargo/env
cargo install cross --version 0.2.1

#Build Envoy-openssl
cd $wdir/${PACKAGE_NAME}
git apply $scriptdir/envoy_openssl_v1.32.patch
bazel/setup_clang.sh $wdir/clang+llvm-14.0.6-powerpc64le-linux-rhel-8.4/
#bazel build -c opt envoy --config=ppc --config=clang --cxxopt=-fpermissive > /dev/null 2>&1 || true
bazel build -c opt envoy --config=ppc --config=clang --cxxopt=-fpermissive || true

#Generating the CARGO_BAZEL_GENERATOR_URL
echo $(find / -name crate_universe)
pushd $(find / -name crate_universe)
#cd $wdir/.cache/bazel/_bazel_envoy/13d7d0439a5c9ee4cb9154fa27853f02/external/rules_rust/crate_universe/
cross build --release --locked --bin cargo-bazel --target=powerpc64le-unknown-linux-gnu
export CARGO_BAZEL_GENERATOR_URL=file://$(pwd)/target/powerpc64le-unknown-linux-gnu/release/cargo-bazel
echo "cargo-bazel build successful!"
popd

cd $wdir/${PACKAGE_NAME}
export PATH=$PATH:$wdir/bazel/output
ret=0
bazel build -c opt envoy --config=ppc --config=clang --cxxopt=-fpermissive || ret=$?
if [ -n "$ret" ]; then
    if [ "$ret" -ne 0 ]; then
        echo "FAIL: Build failed."
        exit 1
    fi
fi
EOF
