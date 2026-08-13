#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : chromadb
# Version       : 1.5.10
# Source repo   : https://github.com/chroma-core/chroma
# Tested on     : UBI:10.2
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Varsha Kumar <varsha.kumar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_DIR=chroma
PACKAGE_NAME=chromadb
PACKAGE_VERSION=${1:-1.5.10}
PACKAGE_URL=https://github.com/chroma-core/chroma.git
CURRENT_DIR=$(pwd)

PROTOC_VERSION=31.1

# -----------------------------------------------------------------------
# Restore libsqlite3.so.0 FIRST — before any yum calls.
# yum/rpm depend on libsqlite3.so.0 via libdnf. On UBI 10 the versioned
# library may be present but the libsqlite3.so.0 symlink missing or broken.
# -----------------------------------------------------------------------
for LIBDIR in /lib64 /usr/lib64; do
    VERSIONED=$(ls ${LIBDIR}/libsqlite3.so.0.* 2>/dev/null | head -1)
    if [ -n "$VERSIONED" ]; then
        ln -sf "$VERSIONED" ${LIBDIR}/libsqlite3.so.0
        ln -sf "$VERSIONED" ${LIBDIR}/libsqlite3.so
    fi
done
ldconfig

# Install dependencies.
# Python packages must appear first (wrapper script requirement).
yum install -y python3.12 python3.12-devel python3.12-pip \
    gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    cmake autoconf unzip make git openblas-devel wget \
    sqlite sqlite-devel

# Configure GCC Toolset 15
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

echo "Using gcc: $(gcc --version | head -1)"

curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable
export PATH="/root/.cargo/bin:$PATH"

PROTOC_ZIP=protoc-${PROTOC_VERSION}-linux-ppcle_64.zip
curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/$PROTOC_ZIP
unzip -o $PROTOC_ZIP -d /usr/local bin/protoc
unzip -o $PROTOC_ZIP -d /usr/local 'include/*'
rm -f $PROTOC_ZIP
chmod +x /usr/local/bin/protoc && \
protoc --version  # Verify installed version

# Install Python build tools
pip install --upgrade pip setuptools wheel build
pip install --upgrade maturin cffi patchelf "setuptools_scm[toml]>=6.2"

# Required for Python 3.14+: PyO3 0.24.x only supports up to 3.13.
# This env var instructs PyO3 to build using the stable ABI anyway.
export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1

cd "$CURRENT_DIR"

# Clone the chroma source
git clone --recursive ${PACKAGE_URL}
cd ${PACKAGE_DIR}

# Checkout version — try v-prefixed tag, bare tag, branch, then fall back to main
if [[ "${PACKAGE_VERSION}" == "latest" ]]; then
    git checkout main
elif git rev-parse "v${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "v${PACKAGE_VERSION}"
elif git rev-parse "${PACKAGE_VERSION}" &>/dev/null; then
    git checkout "${PACKAGE_VERSION}"
else
    echo "WARNING: No tag found for '${PACKAGE_VERSION}', falling back to main"
    git checkout main
fi

git submodule update --init --recursive
# Apply patches
# Only pin the version when a real semver was given; for "latest" leave
# dynamic = ["version"] intact so setuptools_scm derives it from git.
if [[ "$PACKAGE_VERSION" != "latest" ]]; then
    sed -i 's/^dynamic = \["version"\]/version = "'"$PACKAGE_VERSION"'"/' pyproject.toml
fi
sed -i 's/, features = \["abi3-py39"\]/ /' Cargo.toml

# Install the chromadb requirements.
python3.12 -m pip install -r requirements.txt --prefer-binary --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux

cargo update generator
# Build chromadb wheel and install it
if ! python3.12 -m build --wheel --no-isolation --outdir "$CURRENT_DIR/"; then
        echo "------------------$PACKAGE_NAME:build_install_fails---------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub | Fail |  Build_Fails"
        exit 1
fi
pip install "$CURRENT_DIR"/chromadb-*.whl
echo "------------------$PACKAGE_NAME:build_install_success-------------------------"
echo "$PACKAGE_VERSION $PACKAGE_NAME"
echo "$PACKAGE_NAME  | $PACKAGE_VERSION | $OS_NAME | GitHub  | Pass |  Build_Success"

cd "$CURRENT_DIR"

# Build and install pysqlite3 against the UBI 10 system sqlite (v3.46.1),
# which already satisfies chromadb's >= 3.35.0 requirement.
# Using the system sqlite avoids the version mismatch issues seen on UBI 9.
rm -rf pysqlite3
git clone https://github.com/coleifer/pysqlite3.git
cd pysqlite3
python3.12 -m pip install --no-build-isolation .

cd "$CURRENT_DIR"

python3.12 -c "
import sys, pysqlite3
sys.modules['sqlite3'] = pysqlite3
sys.modules['_sqlite3'] = pysqlite3
import chromadb; print(chromadb.__version__)
"
if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Test_Success---------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Pass |  Test_Success"
     exit 0
else
     echo "------------------$PACKAGE_NAME::Test_Fail-------------------------"
     echo "$PACKAGE_VERSION $PACKAGE_NAME"
     echo "$PACKAGE_NAME  | $PACKAGE_URL | $PACKAGE_VERSION  | Fail |  Test_Fail"
     exit 2
fi