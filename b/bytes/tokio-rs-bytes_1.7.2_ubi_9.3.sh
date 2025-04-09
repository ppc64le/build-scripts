#!/usr/bin/env bash
# -----------------------------------------------------------------------------
#
# Package	    : bytes
# Version	    : v1.7.2
# Source repo	: https://github.com/tokio-rs/bytes
# Tested on	    : UBI 9.3
# Language      : Rust
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Onkar Kubal <onkar.kubal@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
SCRIPT_PACKAGE_VERSION=v1.7.2
PACKAGE_NAME=bytes
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/tokio-rs/bytes.git
BUILD_HOME=$(pwd)

# Install update and deps
yum update -y
echo "Installing prerequisites..."
yum install -y git gcc gcc-c++ make clang openssl-devel zlib-devel wget

echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

echo "Configuring the shell..."
source "$HOME/.cargo/env"

# rustc --print=target-list
rustup target add powerpc64le-unknown-linux-gnu
# rustup target add powerpc64-unknown-freebsd

cargo install cargo-hack

# Check if Rust is installed successfully
if command -v rustc &>/dev/null; then
    echo "Rust installed successfully!"
    rustc --version
else
    echo "Rust installation failed."
fi

# set env variable
set RUST_BACKTRACE=full

# Change to home directory
cd $BUILD_HOME


# Build and install tonic
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Run Build
echo "Rust build!"
if ! cargo build --release; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  build_Fails"
    exit 1
fi

# Run install check
echo "Run install check and Test"
if ! cargo test --workspace --all-features; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    export Bytes_Build='/home/bytes/target/release/libbytes.d'
    echo "Bytes Build completed."
    echo "Bytes bit binary is available at [$Bytes_Build]."
    exit 0
fi