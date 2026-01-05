#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : envoy-openssl
# Version       : release/v1.34
# Source repo   : https://github.com/envoyproxy/envoy-openssl/
# Tested on     : RHEL 9.4
# Language      : C++
# Ci-Check  : True
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
SCRIPT_PACKAGE_VERSION=release/v1.34
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}
SCRIPT_PACKAGE_VERSION_WO_LEADING_V="${SCRIPT_PACKAGE_VERSION:1}"

# Install dependencies
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
    java-21-openjdk-devel \
    git \
    gcc-c++ \
    xz \
    file \
    binutils \
    procps \
    diffutils \
    rust \
    cargo \
    diffutils \
    ninja-build \
    sudo

export JAVA_HOME=$(compgen -G '/usr/lib/jvm/java-21-openjdk-*')  
export JRE_HOME=${JAVA_HOME}/jre
export PATH=${JAVA_HOME}/bin:$PATH
scriptdir=$(dirname $(realpath $0))
wdir=/home/envoy
export ENVOY_BIN=$wdir/envoy-openssl/envoy-static
export ENVOY_ZIP=$wdir/envoy-openssl/envoy-static_1.28_UBI9.2.zip

# Find bazel version
wget https://raw.githubusercontent.com/${PACKAGE_ORG}/${PACKAGE_NAME}/${PACKAGE_VERSION}/.bazelversion
export BAZEL_VERSION=$(cat .bazelversion)
rm -rf .bazelversion

useradd envoy
sudo -u envoy -- bash <<EOF
set -ex

# Download Envoy source code
cd $wdir
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}

# Build and setup bazel
cd $wdir
if [ -z "$(ls -A $wdir/bazel)" ]; then
    mkdir bazel
    cd bazel
    wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
    unzip bazel-${BAZEL_VERSION}-dist.zip
    rm -rf bazel-${BAZEL_VERSION}-dist.zip
    env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk" bash ./compile.sh
    #env EXTRA_BAZEL_ARGS="--tool_java_runtime_version=local_jdk --jobs=2" bash ./compile.sh
fi
export PATH=$PATH:$wdir/bazel/output

# Setup clang
cd $wdir
if [ -z "$(ls -A $wdir/clang+llvm-17.0.6-powerpc64le-linux-rhel-8.8)" ]; then
    wget https://github.com/llvm/llvm-project/releases/download/llvmorg-17.0.6/clang+llvm-17.0.6-powerpc64le-linux-rhel-8.8.tar.xz
    tar -xf clang+llvm-17.0.6-powerpc64le-linux-rhel-8.8.tar.xz
    rm -rf clang+llvm-14.0.6-powerpc64le-linux-rhel-8.8.tar.xz
fi
export PATH=/home/envoy/clang+llvm-17.0.6-powerpc64le-linux-rhel-8.8/bin:$PATH

# installing cargo and cross
#curl https://sh.rustup.rs -sSf | sh -s -- -y && source ~/.cargo/env
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && source ~/.cargo/env
cargo install cross --version 0.2.5
export PATH="$wdir/.cargo/bin:$PATH"

# Building cargo-bazel targeting Powerpc64le
cd $wdir
if [ -z "$(ls -A $wdir/rules_rust)" ]; then
	git clone https://github.com/bazelbuild/rules_rust
	cd rules_rust
	git checkout 0.56.0
	cd crate_universe
	#cross build --release --locked --bin cargo-bazel --target=powerpc64le-unknown-linux-gnu
	rustup target add powerpc64le-unknown-linux-gnu
	cargo update
	cargo build --release --locked --bin cargo-bazel
	echo "cargo-bazel build successful!"
fi
export CARGO_BAZEL_GENERATOR_URL=file://$wdir/rules_rust/crate_universe/target/release/cargo-bazel
export CARGO_BAZEL_REPIN=true

# Build Envoy-openssl
ret=0
cd $wdir/${PACKAGE_NAME}
export PATH=$PATH:$wdir/bazel/output
git apply $scriptdir/envoy_openssl_v1.34.patch
bazel/setup_clang.sh $wdir/clang+llvm-17.0.6-powerpc64le-linux-rhel-8.8/
export ENVOY_STDLIB=libstdc++
bazel build -c opt envoy --config=ppc --config=clang --define=wasm=disabled --cxxopt=-fpermissive || ret=$?
if [ -n "$ret" ]; then
    if [ "$ret" -ne 0 ]; then
        echo "FAIL: Build failed."
        exit 1
    fi
fi
EOF
