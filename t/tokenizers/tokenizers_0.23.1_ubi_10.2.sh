#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tokenizers
# Version       : v0.23.1
# Source repo   : https://github.com/huggingface/tokenizers
# Tested on     : UBI:10.2
# Language      : C, Python
# Ci-Check      : True
# Script License: Apache License 2.0
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=tokenizers
PACKAGE_VERSION=${1:-v0.23.1}
PACKAGE_URL=https://github.com/huggingface/tokenizers
PACKAGE_DIR=tokenizers/bindings/python

yum install -y wget gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran git make python3.14 python3.14-devel python3.14-pip openssl-devel cmake unzip rust cargo binutils libatomic pkgconf-pkg-config

export PATH=/opt/rh/gcc-toolset-15/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH

export CC=gcc
export CXX=g++

# Make libatomic available if present
LIBATOMIC=$(gcc -print-file-name=libatomic.so)

if [[ "$LIBATOMIC" != "libatomic.so" && -f "$LIBATOMIC" ]]; then
    LIBATOMIC_DIR=$(dirname "$LIBATOMIC")
    export LIBRARY_PATH=${LIBATOMIC_DIR}:${LIBRARY_PATH:-}
    export LD_LIBRARY_PATH=${LIBATOMIC_DIR}:${LD_LIBRARY_PATH:-}
    export CFLAGS="${CFLAGS:-} -L${LIBATOMIC_DIR}"
    export CXXFLAGS="${CXXFLAGS:-} -L${LIBATOMIC_DIR}"
    export LDFLAGS="${LDFLAGS:-} -L${LIBATOMIC_DIR} -Wl,-rpath,${LIBATOMIC_DIR}"
fi

echo "Installing Python dependencies..."
python3.14 -m ensurepip --upgrade
python3.14 -m pip install --upgrade pip setuptools wheel build maturin setuptools-rust

echo "Cloning and installing..."
git clone "$PACKAGE_URL"
cd "$PACKAGE_NAME"
git checkout "$PACKAGE_VERSION"

cd bindings/python/

export PYO3_PYTHON="$(command -v python3.14)"
export PYTHON_SYS_EXECUTABLE="$PYO3_PYTHON"

echo "Installing test and build dependencies..."
python3.14 -m pip install pytest pytest-asyncio pytest-timeout requests setuptools numpy==2.5.0 tqdm build maturin

echo "Checking pytest installation..."
python3.14 -m pytest --version

echo "Installing tokenizers..."
if ! python3.14 -m pip install . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi

# Skipped these tests as these tests were parity with intel
if ! python3.14 -m pytest \
    --ignore=benches/test_tiktoken.py \
    --ignore=tests/documentation/test_tutorial_train_from_iterators.py \
    -k "not(test_continuing_prefix_trainer_mismatch or test_gzip or test_tiktoken or test_datasets)" ; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi

