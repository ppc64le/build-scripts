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
CURRENT_DIR=$(pwd)

yum install -y \
    python3.14 \
    python3.14-devel \
    python3.14-pip \
    gcc \
    gcc-c++ \
    binutils \
    libatomic \
    make \
    git \
    wget \
    curl \
    pkg-config \
    unzip \
    openssl-devel \
    rust \
    cargo

export PATH="/usr/bin:$PATH"

export CC="$(command -v gcc)"
export CXX="$(command -v g++)"
export AR="$(command -v ar)"
export RANLIB="$(command -v ranlib)"

LIBATOMIC=$(gcc -print-file-name=libatomic.so)

if [[ ! -f "$LIBATOMIC" ]]; then
    echo "ERROR: libatomic.so was not found"
    exit 1
fi

LIBATOMIC_DIR=$(dirname "$LIBATOMIC")

export LIBRARY_PATH="${LIBATOMIC_DIR}:${LIBRARY_PATH:-}"
export LD_LIBRARY_PATH="${LIBATOMIC_DIR}:${LD_LIBRARY_PATH:-}"

export CFLAGS="${CFLAGS:-} -L${LIBATOMIC_DIR}"
export CXXFLAGS="${CXXFLAGS:-} -L${LIBATOMIC_DIR}"
export LDFLAGS="${LDFLAGS:-} -L${LIBATOMIC_DIR} -Wl,-rpath,${LIBATOMIC_DIR}"

export PATH="/usr/bin:${PATH}"

command -v rustc
command -v cargo

rustc --version
cargo --version

python3.14 -m ensurepip --upgrade

python3.14 -m pip install --upgrade \
    pip \
    setuptools \
    wheel \
    build \
    maturin \
    setuptools-rust

cd "$CURRENT_DIR"

if [[ ! -d "$PACKAGE_NAME" ]]; then
    git clone "$PACKAGE_URL"
fi

cd "$PACKAGE_NAME"

git fetch --tags

git checkout "$PACKAGE_VERSION"

cd bindings/python

export PYO3_PYTHON="$(command -v python3.14)"
export PYTHON_SYS_EXECUTABLE="$PYO3_PYTHON"

rm -rf build

python3.14 -m pip install pytest setuptools tiktoken numpy==2.5.0 tqdm

if ! python3.14 -m pip install . --no-build-isolation; then
    echo "------------------${PACKAGE_NAME}:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_Fails"
    exit 1
fi

# Skipped these tests as these tests were parity with intel
if ! pytest -k "not(test_continuing_prefix_trainer_mismatch or test_gzip or test_tiktoken or test_datasets)"; then
    echo "------------------${PACKAGE_NAME}:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------${PACKAGE_NAME}:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi

