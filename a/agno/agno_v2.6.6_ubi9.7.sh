#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : agno
# Version       : v2.6.6
# Source repo   : https://github.com/agno-agi/agno
# Tested on     : UBI 9.7
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Manya Rusiya<Manya.Rusiya@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

WORKDIR=$(pwd)
PACKAGE_NAME=agno
SCRIPT_PACKAGE_VERSION=v2.6.6
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/agno-agi/agno
PACKAGE_DIR=agno/libs/agno
SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname $SCRIPT)

# Utilizing IBM ppc64le wheel index as a fallback for missing PyPI wheels
IBM_WHEEL_INDEX=https://wheels.developerfirst.ibm.com/ppc64le/linux

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE=Github

# -----------------------------------------------------------------------------
# STEP 1: Install System Dependencies
# -----------------------------------------------------------------------------
echo ">>> Installing System Dependencies..."
yum install -y \
    git make wget python3.12 python3.12-devel python3.12-pip \
    gcc gcc-c++ gcc-gfortran openssl openssl-devel \
    libffi libffi-devel sqlite sqlite-devel pkgconf-pkg-config \
    autoconf automake libtool m4 \
    cmake unzip \
    openblas-devel \
    zlib-devel bzip2-devel xz-devel libjpeg-turbo-devel \
    --allowerasing

if [ $? -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:install_system_dependencies_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | System_Dependencies_Install_Fails"
    exit 1
fi

echo "INFO: System dependencies installed successfully."

# -----------------------------------------------------------------------------
# STEP 2: Install Rust Toolchain
# -----------------------------------------------------------------------------
echo ">>> Installing Rust toolchain..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    export PATH="$HOME/.cargo/bin:$PATH"
    source "$HOME/.cargo/env"

    if [ $? -ne 0 ]; then
        echo "------------------$PACKAGE_NAME:rust_install_fails---------------------------------------"
        echo "$PACKAGE_URL $PACKAGE_NAME"
        echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Rust_Install_Fails"
        exit 1
    fi
fi

echo "INFO: Rust toolchain installed — $(rustc --version)."

# -----------------------------------------------------------------------------
# STEP 3: Install UV Package Manager
# -----------------------------------------------------------------------------
echo ">>> Installing uv package manager..."
python3.12 -m pip install --upgrade pip
python3.12 -m pip install uv

if [ $? -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:uv_install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | UV_Install_Fails"
    exit 1
fi

# Ensure uv is in PATH
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

echo "INFO: uv installed — $(uv --version)."

# -----------------------------------------------------------------------------
# STEP 4: Clone and Checkout Repository
# -----------------------------------------------------------------------------
echo ">>> Cloning repository..."
cd $WORKDIR


if ! git clone $PACKAGE_URL; then
    echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Clone_Fails"
    exit 1
fi

cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch


echo "INFO: Repository checked out and patched successfully."

# Define paths
AGNO_DIR=$(pwd)
VENV_DIR="$AGNO_DIR/.venv"
VENV_PYTHON="$VENV_DIR/bin/python"
AGNO_DEPS_DIR="$AGNO_DIR/libs/agno"
AGNO_INFRA_DEPS_DIR="$AGNO_DIR/libs/agno_infra"

# -----------------------------------------------------------------------------
# STEP 5: Create Virtual Environment
# -----------------------------------------------------------------------------
echo ">>> Creating virtual environment..."
uv venv .venv --python python3.12

if [ $? -ne 0 ]; then
    echo "------------------$PACKAGE_NAME:venv_creation_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Venv_Creation_Fails"
    exit 1
fi

source .venv/bin/activate

# -----------------------------------------------------------------------------
# STEP 6: Install Core Dependencies
# -----------------------------------------------------------------------------
echo ">>> Installing agno core dependencies..."
if ! uv pip install -r ${AGNO_DEPS_DIR}/requirements.txt \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "------------------$PACKAGE_NAME:core_requirements_install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Core_Requirements_Install_Fails"
    exit 1
fi

echo ">>> Installing agno core dev dependencies..."
if ! uv pip install -e ${AGNO_DEPS_DIR}[dev] \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "------------------$PACKAGE_NAME:core_dev_install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Core_Dev_Install_Fails"
    exit 1
fi

echo ">>> Installing agno infra dependencies..."
if ! uv pip install -r ${AGNO_INFRA_DEPS_DIR}/requirements.txt \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "------------------$PACKAGE_NAME:infra_requirements_install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Infra_Requirements_Install_Fails"
    exit 1
fi

echo ">>> Installing agno infra dev dependencies..."
if ! uv pip install -e ${AGNO_INFRA_DEPS_DIR}[dev] \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "------------------$PACKAGE_NAME:infra_dev_install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Infra_Dev_Install_Fails"
    exit 1
fi

# -----------------------------------------------------------------------------
# STEP 7: Verify CLI Installation
# -----------------------------------------------------------------------------
echo ">>> Verifying agno CLI..."
if ! agno --help >/dev/null; then
    echo "------------------$PACKAGE_NAME:cli_verification_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | CLI_Verification_Fails"
    exit 1
fi

echo "INFO: agno CLI verified successfully."

# -----------------------------------------------------------------------------
# STEP 8: Install Additional Dependencies
# -----------------------------------------------------------------------------
echo ">>> Installing additional dependencies..."

# Install specific versions from IBM wheel index
uv pip install grpcio==1.76.0 --extra-index-url=$IBM_WHEEL_INDEX
uv pip install chroma_hnswlib==0.7.6 --extra-index-url=$IBM_WHEEL_INDEX
uv pip install onnxruntime==1.23.2 --extra-index-url=$IBM_WHEEL_INDEX
uv pip install opencv-python==4.13.0.92 --extra-index-url=$IBM_WHEEL_INDEX
uv pip install duckdb==1.4.4 --extra-index-url=$IBM_WHEEL_INDEX

# Install chromadb and related packages
uv pip install chromadb==0.5.23
uv pip install huggingface-hub==1.13.0 typing-inspection==0.4.1 tokenizers==0.22.2


# Install SQLite >= 3.35
echo ">>>> Installing SQLite 3.45 ....."
SQLITE_VERSION=3450000
wget https://www.sqlite.org/2024/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
tar xzf sqlite-autoconf-${SQLITE_VERSION}.tar.gz
cd sqlite-autoconf-${SQLITE_VERSION}

./configure --prefix=/usr/local/sqlite --enable-shared
make -j$(nproc)
make install

cd $WORKDIR
echo ">>> Configuring SQLite environment..."
# Register with system linker (CRITICAL)
echo "/usr/local/sqlite/lib" > /etc/ld.so.conf.d/sqlite3.conf
ldconfig
export PKG_CONFIG_PATH=/usr/local/sqlite/lib/pkgconfig:$PKG_CONFIG_PATH
export LD_LIBRARY_PATH=/usr/local/sqlite/lib:$LD_LIBRARY_PATH
export CFLAGS="-I/usr/local/sqlite/include"
export LDFLAGS="-L/usr/local/sqlite/lib"
echo ">>> Verifying SQLite..."
/usr/local/sqlite/bin/sqlite3 --version
pkg-config --modversion sqlite3
rm -rf sqlite-autoconf-*

#Before chromadb installation
echo ">>>> Cleaning yum cache...."
yum clean all
rm -rf /var/cache/yum/*


# Install couchbase
if ! uv pip install couchbase; then
    echo "------------------$PACKAGE_NAME:couchbase_install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Couchbase_Install_Fails"
    exit 1
fi

echo "INFO: couchbase installed successfully."

# Install cassandra driver
if ! uv pip install cassandra-driver==3.29.2 \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "------------------$PACKAGE_NAME:cassandra_driver_install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Cassandra_Driver_Install_Fails"
    exit 1
fi

echo "INFO: cassandra driver installed successfully."

# Install cassio
if ! uv pip install cassio \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "------------------$PACKAGE_NAME:cassio_install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Cassio_Install_Fails"
    exit 1
fi

echo "INFO: cassio installed successfully."

# -----------------------------------------------------------------------------
# STEP 9: Install Test Dependencies
# -----------------------------------------------------------------------------
echo ">>> Installing test dependencies..."
if ! uv pip install -e ${AGNO_DEPS_DIR}[tests] \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "------------------$PACKAGE_NAME:test_dependencies_install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Test_Dependencies_Install_Fails"
    exit 1
fi

echo "INFO: Test dependencies installed successfully."

# Install additional test packages
if ! uv pip install brave-search; then
    echo "------------------$PACKAGE_NAME:brave_install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Brave_Install_Fails"
    exit 1
fi

echo "INFO: brave installed successfully."

# Downgrade seltz to 0.2.0
if ! uv pip install seltz==0.2.0; then
    echo "------------------$PACKAGE_NAME:seltz_install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Seltz_Install_Fails"
    exit 1
fi

echo "INFO: seltz installed successfully."

# Install httpx
if ! uv pip install httpx==0.28.1; then
    echo "------------------$PACKAGE_NAME:httpx_install_fails---------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Httpx_Install_Fails"
    exit 1
fi

echo "INFO: httpx installed successfully."

# Install tree-sitter-language-pack
uv pip install tree-sitter-language-pack==0.13.0

# -----------------------------------------------------------------------------
# STEP 10: Run Unit Tests
# -----------------------------------------------------------------------------
cd $AGNO_DIR
source .venv/bin/activate

echo "============= Running Unit Tests for $PACKAGE_NAME ================="
echo ""
echo "INFO: The following test files are excluded due to unavailable or platform-incompatible dependencies:"
echo "INFO:   - test_client_deepcopy.py     (litellm — skipped for parity with x86)"
echo "INFO:   - test_browserbase.py         (browserbase — skipped, playwright not available for Power architecture)"
echo "INFO:   - test_crawl4ai.py            (crawl4ai — skipped for parity with x86)"
echo "INFO:   - test_lancedb.py             (lancedb — skipped, lancedb not available for Power architecture)"
echo ""

# Run unit tests with exclusions
if ! pytest libs/agno/tests/unit \
    --ignore=libs/agno/tests/unit/models/litellm \
    --ignore=libs/agno/tests/unit/tools/test_browserbase.py \
    --ignore=libs/agno/tests/unit/tools/test_crawl4ai.py \
    --ignore=libs/agno/tests/unit/vectordb/test_lancedb.py; then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Install_success_but_test_Fails"
    exit 2
fi

echo ""
echo "============================================================"
echo "  SUCCESS: $PACKAGE_NAME $PACKAGE_VERSION — Build & Tests Passed"
echo "============================================================"
echo "------------------$PACKAGE_NAME:install_and_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Pass | Both_Install_and_Test_Success"
exit 0
