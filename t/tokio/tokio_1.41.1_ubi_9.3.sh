#!/usr/bin/env bash
# -----------------------------------------------------------------------------
#
# Package	    : tokio
# Version	    : tokio-1.41.1
# Source repo	: https://github.com/tokio-rs/tokio
# Tested on	    : UBI 9.3
# Language      : Rust
# Travis-Check  : true
# Script License: Apache License, Version 2 or later
# Maintainer	: Onkar Kubal <onkar.kubal@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========    platform using the mentioned version of the package.
#               It may not work as expected with newer versions of the
#               package and/or distribution. In such case, please
#               contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -e
SCRIPT_PACKAGE_VERSION=tokio-1.41.1
PACKAGE_NAME=tokio
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/tokio-rs/tokio.git
BUILD_HOME=$(pwd)

# Install update and deps

yum update -y
echo "Installing prerequisites..."
yum install -y git gcc gcc-c++ make clang openssl-devel zlib-devel

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

# Build and install tokio
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Run Build
echo "Rust build!"
if ! cargo build --all-features --target powerpc64le-unknown-linux-gnu; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  build_Fails"
    exit 1
fi

# Run install check
echo "Run install check and Test"
if ! cargo check --all --all-features --target powerpc64le-unknown-linux-gnu && cargo test -p tokio --test fs_try_exists --target powerpc64le-unknown-linux-gnu; then
    echo "------------------$PACKAGE_NAME:install_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    export TOKIO_Build='/home/tokio/target/powerpc64le-unknown-linux-gnu/debug/libtokio.d'
    echo "TOKIO Build completed."
    echo "TOKIO bit binary is available at [$TOKIO_Build]."
    #echo "------------------$PACKAGE_NAME:run_tokio_example-------------------------"
    #cargo run --example custom-executor-tokio-context
    #cargo run --example custom-executor
    exit 0
fi
