#!/bin/bash -ex
# ----------------------------------------------------------------------------
# Package        : connectorx
# Version        : v0.4.6
# Source repo    : https://github.com/sfu-db/connector-x.git
# Tested on      : UBI 9.8
# Language       : Python, Rust
# Ci-Check       : True
# Maintainer     : Pratik Tonage <Pratik.Tonage@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# ----------------------------------------------------------------------------

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="connectorx"
PACKAGE_VERSION=${1:-v0.4.6}
PACKAGE_URL="https://github.com/sfu-db/connector-x.git"
SCRIPT_PATH=$(dirname $(realpath $0))
BUILD_HOME="$(pwd)"

# ----------------------
# Install required repos
# ----------------------
echo "Configuring package repositories..."
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256

# ---------------------------
# Dependency Installation
# ---------------------------

yum install -y python3.12 python3.12-pip python3.12-devel make
yum install -y \
    gcc gcc-c++ cmake git wget curl-minimal openssl \
    openblas-devel openssl-devel protobuf-devel clang-libs clang-devel \
    pkgconf-pkg-config perl-core ca-certificates patchelf \
    zlib-devel libffi-devel sqlite sqlite-devel clang clang-devel krb5-devel \
    unzip mysql-devel postgresql-devel freetds-devel libatomic bison libverto-libev

# Install Rust
curl --proto '=https' --tlsv1.3 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"
rustc --version && cargo --version

ln -sf "$(command -v python3.12)" /usr/bin/python3
ln -sf "$(command -v pip3.12)" /usr/bin/pip3
	  
# ---------------------------
# Clone Repository
# --------------------------- 
cd "${BUILD_HOME}"
git clone $PACKAGE_URL
cd connector-x/connectorx-python
git checkout $PACKAGE_VERSION

# Install Python build tools
python3.12 -m pip install --upgrade pip pipx 
python3.12 -m pip install maturin pytest setuptools wheel build 

# ---------------------------
# Build
# ---------------------------
if ! maturin build --release; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

export CONNECTORX_WHEEL="$(find target/wheels -maxdepth 1 -type f -name '*.whl' | head -n 1)"
test -f ${CONNECTORX_WHEEL}
cp "$CONNECTORX_WHEEL" "$BUILD_HOME/"

# ----------------------------------------------
# Install required tools and Prepare test setup
# ----------------------------------------------
python3.12 -m pip install "$CONNECTORX_WHEEL"
python3.12 -m pip install pandas numpy "poetry==2.4.1"
python3.12 -m pip install --prefer-binary --no-cache-dir polars==1.44.2 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
python3.12 -m pip install --prefer-binary --no-cache-dir pyarrow==24.0.0 --extra-index-url=https://wheels.developerfirst.ibm.com/ppc64le/linux
unzip -o "$CONNECTORX_WHEEL" 'connectorx/*.so' 'connectorx.libs/*' -d .
# ---------------------------
# Test
# ---------------------------
if ! python3.12 -m pytest connectorx/tests -v -s; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi

# ---------------------------
# Conclude
# ---------------------------
set +ex
echo "Complete: Build and Test successful!"
echo "connectorx wheel available at [$CONNECTORX_WHEEL]"
