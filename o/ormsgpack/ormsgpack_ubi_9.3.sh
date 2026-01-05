#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package        : ormsgpack
# Version        : 1.9.1
# Source repo    : https://github.com/aviramha/ormsgpack.git
# Tested on      : UBI 9.3
# Language       : Python/Rust
# Ci-Check   : True
# Script License : Apache License, Version 2 or later
# Maintainer     : Vivek Sharma <vivek.sharma20@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
set -e
PACKAGE_NAME=ormsgpack
PACKAGE_DIR=ormsgpack
PACKAGE_VERSION=${1:-1.9.1}
PACKAGE_URL=https://github.com/aviramha/ormsgpack.git
RUST_VERSION=1.81.0

yum install -y git gcc gcc-c++ python-devel gzip tar make wget xz cmake yum-utils openssl-devel     openblas-devel bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf     automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le     fontconfig-devel.ppc64le sqlite-devel

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain "$RUST_VERSION"
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
else
    echo "[ERROR] Rust environment not found!"
    exit 1
fi
rustup update stable
rustup default $RUST_VERSION
rustup install nightly
rustup default nightly
rustc --version

# Set up Python environment
pip3 install --upgrade pip
pip3 install --upgrade --ignore-installed chardet tox pytz maturin pytest msgpack pydantic numpy

# Clone the repository
git clone ${PACKAGE_URL}
cd ${PACKAGE_DIR}
git checkout ${PACKAGE_VERSION}

# Build and install the package
if ! maturin build --release; then
    echo "------------------$PACKAGE_NAME:install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests using tox
if ! tox; then
    echo "------------------$PACKAGE_NAME: Tests_Fail------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Tests_Fail"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Install & test both success ---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi

