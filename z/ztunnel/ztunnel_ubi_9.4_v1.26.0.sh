#!/bin/bash -ex
# ----------------------------------------------------------------------------
#
# Package       : ztunnel
# Version       : v1.26.0
# Source repo   : https://github.com/istio/ztunnel
# Tested on     : RHEL 9.4
# Language      : Rust
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Anurag Chitrakar <Anurag.Chitrakar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of theztunnel_ubi_9.4_v1.26.0.sh
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=ztunnel
PACKAGE_ORG=istio
SCRIPT_PACKAGE_VERSION=release-1.26
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}
RUST_VERSION=1.85.1
TOOLCHAIN=powerpc64le-unknown-linux-gnu

# Install dependencies
yum install -y --allowerasing  git wget curl unzip gcc pkg-config openssl-devel clang-devel cmake iproute procps-ng iptables

wget https://github.com/protocolbuffers/protobuf/releases/download/v30.2/protoc-30.2-linux-ppcle_64.zip
unzip protoc-30.2-linux-ppcle_64.zip
mv ./bin/protoc /usr/local/bin/
protoc --version

# Installing Rust
curl -sSL "https://static.rust-lang.org/dist/rust-${RUST_VERSION}-${TOOLCHAIN}.tar.gz" -o rust.tar.gz
tar xzf rust.tar.gz
rm rust.tar.gz
mv rust-${RUST_VERSION}-${TOOLCHAIN} /opt/rust-${RUST_VERSION}
/opt/rust-${RUST_VERSION}/install.sh

# Download Ztunnel source code
git clone ${PACKAGE_URL}
cd ${PACKAGE_NAME} && git checkout ${PACKAGE_VERSION}

# Build ztunnel
cargo build --no-default-features --features tls-openssl --release

# testing ztunnel
# cargo test --no-default-features --features tls-openssl -- --test-threads 1 
# Skipping this test on Travis CI as it requires privileged containers (e.g. --privileged, --cap-add CAP_SYS_ADMIN, --cap-add CAP_NET_ADMIN, --network host),
# which are not supported in Travis due to its restriction on Docker-in-Docker (DinD). 
# we can't create desier container as it gives you the default container
# The `cargo test` command below is used to test ztunnel in a privileged container environment and must be run manually or in a CI system that allows such capabilities.
