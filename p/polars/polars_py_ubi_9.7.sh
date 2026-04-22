#!/bin/bash -ex
# ----------------------------------------------------------------------------
# Package        : polars
# Version        : py-1.38.1
# Source repo    : https://github.com/pola-rs/polars
# Tested on      : UBI 9.7
# Language       : Python, Rust
# Ci-Check       : true
# Maintainer     : Sumit Dubey <sumit.dubey2@ibm.com>
# Script License : Apache License, Version 2.0 or later
#
# Disclaimer     : This script has been tested in root mode on the specified
#                  platform and package version. Functionality with newer
#                  versions of the package or OS is not guaranteed.
# ----------------------------------------------------------------------------

# ---------------------------
# Configuration
# ---------------------------
PACKAGE_NAME="polars"
PACKAGE_ORG="pola-rs"
SCRIPT_PKG_VERSION=py-1.38.1
PACKAGE_VERSION=${SCRIPT_PKG_VERSION}
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
SCRIPT_PATH=$(dirname $(realpath $0))
RUNTESTS=1
BUILD_HOME="$(pwd)"
PYTHON_VERSION=3.11.14
PYTHON_VERSION_WO_DOTS=${PYTHON_VERSION//./}
BAZEL_VERSION=6.5.0

# ----------------------
# Install required repos
# ----------------------
echo "Configuring package repositories..."
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
ret=0
dnf config-manager --set-enabled codeready-builder-for-rhel-9-$(arch)-rpms || ret=$?
if [ $ret -ne 0 ]; then
        yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os
        yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/AppStream//ppc64le/os
        yum config-manager --add-repo https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os
        rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official-SHA256
fi

# ---------------------------
# Remove python if exists
# ---------------------------
yum remove -y python3.11 python3.11-devel python3.11-pip python3.11-setuptools

# ---------------------------
# Dependency Installation
# ---------------------------
echo "Installing required packages..."
yum install -y git wget gcc gcc-c++ perl-IPC-Cmd perl-FindBin perl-File-Compare krb5-devel perl-File-Copy patchelf cmake ninja-build libzstd-devel libedit-devel zlib-devel re2-devel libcurl-devel libjpeg-turbo-devel gfortran openblas-devel openssl-devel protobuf-devel protobuf-compiler libffi-devel expat-devel bzip2-devel xz-devel readline-devel ncurses-devel gdbm-devel libuuid-devel graphviz java-11-openjdk-devel zip unzip
export CC=gcc
export CXX=g++

# --------------------------------------
# Install sqlite 3.51.3 from source
# --------------------------------------
cd "${BUILD_HOME}"
if [ -z "$(ls -A $BUILD_HOME/sqlite-autoconf-3510300)" ]; then
        wget https://sqlite.org/2026/sqlite-autoconf-3510300.tar.gz
        tar -xzf sqlite-autoconf-3510300.tar.gz
        rm -rf sqlite-autoconf-3510300.tar.gz
        cd sqlite-autoconf-3510300
        ./configure --prefix=/usr/
        make -j$(nproc)
else
        cd sqlite-autoconf-3510300
fi
make install
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH

# ------------------------------------
# Build Python from source and install
# ------------------------------------
cd "${BUILD_HOME}"
if [ -z "$(ls -A $BUILD_HOME/Python-${PYTHON_VERSION})" ]; then
        wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz
        tar -xzf Python-${PYTHON_VERSION}.tgz
        rm -rf Python-${PYTHON_VERSION}.tgz
        cd Python-${PYTHON_VERSION}
        ./configure --prefix=/usr/ --with-system-expat -with-system-ffi
else
        cd Python-${PYTHON_VERSION}
fi
make altinstall -j$(nproc)
ln -sf /usr/bin/python${PYTHON_VERSION:0:4} /usr/bin/python3
ln -sf /usr/bin/pip${PYTHON_VERSION:0:4} /usr/bin/pip3
ln -sf /usr/bin/python${PYTHON_VERSION:0:4} /usr/bin/python
ln -sf /usr/bin/pip${PYTHON_VERSION:0:4} /usr/bin/pip
pip install numpy wheel build maturin pytest "setuptools<71"

# ---------------------------
# Install Rust
# ---------------------------
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env"
rustup toolchain install 1.93.0
rustup default 1.93.0-powerpc64le-unknown-linux-gnu

# ---------------------------
# Clone and Prepare Repository
# ---------------------------
cd "${BUILD_HOME}"
if [ -z "$(ls -A $BUILD_HOME/${PACKAGE_NAME})" ]; then
	git clone "${PACKAGE_URL}"
	cd "${PACKAGE_NAME}"
	git checkout "${PACKAGE_VERSION}"
	wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/p/polars/polars_py-1.38.1.patch
	git apply polars_py-1.38.1.patch
else
        cd "${PACKAGE_NAME}"
fi

# ---------------------------
# Build
# ---------------------------
ret=0
cd py-polars
python -m build --wheel ||  ret=$?
if [ $ret -ne 0 ]; then
        set +ex
        echo "------------------ ${PACKAGE_NAME}: Build Failed ------------------"
        exit 1
fi
cd ..
export PYPOLARS_WHEEL=${BUILD_HOME}/${PACKAGE_NAME}/py-polars/dist/polars-${PACKAGE_VERSION:3}-py3-none-any.whl
test -f ${PYPOLARS_WHEEL}
cp "$PYPOLARS_WHEEL" "$BUILD_HOME/"


#This script is for temporary purpose don't refer to this script refer polars_py-1.38.1_ubi9.7.sh build_script for overall purpose.
