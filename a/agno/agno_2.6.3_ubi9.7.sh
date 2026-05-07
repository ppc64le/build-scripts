#!/bin/bash -ex
# -----------------------------------------------------------------------------
#
# Package       : agno
# Version       : v2.6.3
# Source repo   : https://github.com/agno-agi/agno
# Tested on     : UBI 9.7
# Ci-Check      : True
# Language      : Python
# Script License: Apache License, Version 2 or later
# Maintainer    : Prachi Gaonkar <Prachi.Gaonkar@ibm.com>
#
# Disclaimer    : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
# -----------------------------------------------------------------------------

WORKDIR=$(pwd)
PACKAGE_NAME=agno
SCRIPT_PACKAGE_VERSION=v2.6.3
PACKAGE_VERSION=${1:-${SCRIPT_PACKAGE_VERSION}}
PACKAGE_URL=https://github.com/agno-agi/agno
PACKAGE_DIR=agno
SCRIPT=$(readlink -f $0)
SCRIPT_PATH=$(dirname $SCRIPT)

# Utilizing IBM ppc64le wheel index as a fallback for missing PyPI wheels
IBM_WHEEL_INDEX=https://wheels.developerfirst.ibm.com/ppc64le/linux

# -----------------------------------------------------------------------------
# STEP 1 — SYSTEM DEPENDENCIES
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

echo "INFO: System dependencies installed."

# -----------------------------------------------------------------------------
# STEP 2 — RUST TOOLCHAIN
# -----------------------------------------------------------------------------
echo ">>> Installing Rust toolchain..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH="$HOME/.cargo/bin:$PATH"
source "$HOME/.cargo/env"

echo "INFO: Rust toolchain installed — $(rustc --version)."

# -----------------------------------------------------------------------------
# STEP 3 — UV PACKAGE MANAGER
# -----------------------------------------------------------------------------
echo ">>> Installing uv package manager..."
python3.12 -m pip install --upgrade pip
python3.12 -m pip install uv
# Ensure uv is in PATH
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

echo "INFO: uv installed — $(uv --version)."

# -----------------------------------------------------------------------------
# STEP 4 — CLONE & CHECKOUT AGNO REPOSITORY
# -----------------------------------------------------------------------------
echo ">>> Cloning repository..."
cd $WORKDIR
if [ -d "$PACKAGE_DIR" ]; then
    echo ">>> Removing existing directory $PACKAGE_DIR..."
    rm -rf "$PACKAGE_DIR"
fi
git clone $PACKAGE_URL
cd $PACKAGE_DIR
# Derived paths — defined here so they are available for all later steps
AGNO_DIR=$(pwd)
VENV_DIR="$AGNO_DIR/.venv"
VENV_PYTHON="$VENV_DIR/bin/python"
AGNO_DEPS_DIR="$AGNO_DIR/libs/agno"
AGNO_INFRA_DEPS_DIR="$AGNO_DIR/libs/agno_infra"

git checkout $PACKAGE_VERSION
# apply patch
git apply ${SCRIPT_PATH}/${PACKAGE_NAME}_${SCRIPT_PACKAGE_VERSION}.patch

echo "INFO: Repository checked out and patched successfully." 

# -----------------------------------------------------------------------------
# STEP 5 — CREATE VIRTUAL ENVIRONMENT
# -----------------------------------------------------------------------------
echo ">>> Creating virtual environment..."
uv venv .venv --python python3.12
VENV_PYTHON="$(pwd)/.venv/bin/python"

# -----------------------------------------------------------------------------
# STEP 6 — INSTALL AGNO CORE & INFRA DEPENDENCIES
# -----------------------------------------------------------------------------
# Note: uv will automatically read pyproject.toml and install all pinned dependecies
source .venv/bin/activate
if ! uv pip install -r ${AGNO_DEPS_DIR}/requirements.txt \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "ERROR: $PACKAGE_NAME - Requirement installation failed."
    exit 1
fi

if ! uv pip install -e ${AGNO_DEPS_DIR}[dev] \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "ERROR: $PACKAGE_NAME - Dev Dependency installation failed."
    exit 1
fi

if ! uv pip install -r ${AGNO_INFRA_DEPS_DIR}/requirements.txt \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "ERROR: $PACKAGE_NAME - Infra Requirement installation failed"
    exit 1
fi

if ! uv pip install -e ${AGNO_INFRA_DEPS_DIR}[dev] \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "ERROR: $PACKAGE_NAME - Infra Dev Dependency installation failed"
fi

# 7. Verify CLI
if ! agno --help >/dev/null; then
    echo "ERROR: $PACKAGE_NAME - agno CLI failed to execute"
    exit 2
else
    echo "INFO: agno CLI executed successfully"
fi

deactivate

# -----------------------------------------------------------------------------
# STEP 7 — BUILD & INSTALL grpcio
# -----------------------------------------------------------------------------
cd $WORKDIR
echo ">>>> Installing grpcio"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/g/grpcio/grpcio_1.76.0_ubi_9.6.sh
sed -i '/git submodule update --init --recursive/a \
\n# Setting up agno venv\nVENV_PYTHON="'"$AGNO_DIR"'/.venv/bin/python"\n' grpcio_1.76.0_ubi_9.6.sh
sed -i 's|pip3 install -r requirements.txt|uv pip install --python $VENV_PYTHON -r requirements.txt|' grpcio_1.76.0_ubi_9.6.sh
sed -i 's|pip3 install --force-reinstall Cython==0.29.37|uv pip install --python $VENV_PYTHON --force-reinstall Cython==0.29.37|' grpcio_1.76.0_ubi_9.6.sh
sed -i 's|pip3 install \. --no-build-isolation|uv pip install --python $VENV_PYTHON . --no-build-isolation|' grpcio_1.76.0_ubi_9.6.sh
sed -i 's|python3 -c|$VENV_PYTHON -c|' grpcio_1.76.0_ubi_9.6.sh
chmod +x grpcio_1.76.0_ubi_9.6.sh

ret=0
./grpcio_1.76.0_ubi_9.6.sh v1.78.0 || ret=$?
if [ $ret -ne 0 ]
then
    echo "grpcio failed to download and install"
    exit 1
else
    echo "INFO: grpcio installed successfully"
    rm -rf grpc
    rm -f grpcio_1.76.0_ubi_9.6.sh
fi

# -----------------------------------------------------------------------------
# STEP 8 — BUILD & INSTALL SQLite >= 3.35 (required by chromadb)
# -----------------------------------------------------------------------------
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

# -----------------------------------------------------------------------------
# STEP 9 — BUILD & INSTALL chromadb
# -----------------------------------------------------------------------------
echo ">>>> Installing chromadb"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/c/chromadb/chromadb_1.0.20_ubi_9.6.sh
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/c/chromadb/chromadb_1.0.20_ubi_9.6.patch
# Inject VENV_PYTHON dynamically + SQLite environment
echo "INFO: Patching chromadb script — injecting venv, SQLite env, skipping redundant yum installs, replacing python3.11 with uv pip, removing upstream tests..."
sed -i "
/^set -e/a VENV_PYTHON=\"$AGNO_DIR/.venv/bin/python\";\
export PKG_CONFIG_PATH=/usr/local/sqlite/lib/pkgconfig:\$PKG_CONFIG_PATH;\
export LD_LIBRARY_PATH=/usr/local/sqlite/lib:\$LD_LIBRARY_PATH;\
export CFLAGS=\"-I/usr/local/sqlite/include\";\
export LDFLAGS=\"-L/usr/local/sqlite/lib -Wl,-rpath,/usr/local/sqlite/lib\";
s|yum -y install gcc g++ cmake autoconf unzip make git python3.11 python3.11-pip python3.11-devel|echo 'Skipping yum install - packages already present'|;
s|python3.11 -m pip install --upgrade maturin cffi patchelf setuptools wheel build|uv pip install --python \$VENV_PYTHON --upgrade maturin cffi patchelf setuptools wheel build|;
s|python3.11 -m pip install -r requirements.txt --prefer-binary --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux|uv pip install --python \$VENV_PYTHON -r requirements.txt  --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux --index-strategy unsafe-best-match|;
s|python3.11 -m pip install \.|uv pip install --python \$VENV_PYTHON .|;
/# Test wheel after installation/,\$d
" chromadb_1.0.20_ubi_9.6.sh
chmod +x chromadb_1.0.20_ubi_9.6.sh

# Verify environment before build
echo ">>> Pre-chromadb environment check..."
echo "PKG_CONFIG_PATH: $PKG_CONFIG_PATH"
echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
pkg-config --modversion sqlite3 || echo "WARNING: pkg-config cannot find sqlite3"

ret=0
./chromadb_1.0.20_ubi_9.6.sh || ret=$?
if [ $ret -ne 0 ]
then
    echo "ERROR: chromadb failed to download and install"
    exit 1 
else
    echo "INFO: chromadb installed successfully"
    rm -rf chroma
    rm -rf chromadb_1.0.20_ubi_9.6.sh
    rm -rf chromadb_1.0.20_ubi_9.6.patch
fi

# The following packages are installed individually (not via agno[tests]) because
# they cause OOM errors when resolved alongside the full test extras in one pass. 
cd $AGNO_DIR
if ! uv pip install opencv-python; then
    echo "ERROR: opencv failed to install"
    exit 1
else
    echo "INFO: opencv-python installed succesfully"
fi

if ! uv pip install couchbase; then
    echo "ERROR: couchbase failed to Install"
    exit 1
else
    echo "INFO: couchbase installed successfully"
fi

if ! uv pip install duckdb; then
    echo "ERROR: duckdb failed to install"
    exit 1 
else
    echo "INFO: duckdb installed successfully"
    
fi

if ! uv pip install cassandra-driver==3.29.2 \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "ERROR: cassandra driver failed to install"
    exit 1 
else
    echo "INFO: cassandra driver installed successfully"
fi

if ! uv pip install cassio \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "ERROR: cassio failed to install"
    exit 1 
else
    echo "INFO: cassio installed succesfully"
fi

# -----------------------------------------------------------------------------
# STEP 10 — INSTALL REMAINING TEST DEPENDENCIES
# -----------------------------------------------------------------------------
if ! uv pip install -e ${AGNO_DEPS_DIR}[tests] \
    --extra-index-url $IBM_WHEEL_INDEX \
    --index-strategy unsafe-best-match; then
    echo "ERROR: $PACKAGE_NAME - Test Dependency installation failed."
    exit 1
else
    echo "INFO : $PACKAGE_NAME - Test Dependency installed successfully"
fi

if ! uv pip install brave-search; then 
    echo "ERROR: brave failed to install"
    exit 1
else
    echo "INFO: brave installed successfully"
fi
# downgrading seltz to 0.2.0
if ! uv pip install seltz==0.2.0; then
    echo "ERROR: seltz failed to install"
    exit 1
else
    echo "INFO: seltz installed successfully"
fi

if ! uv pip install httpx==0.28.1; then
    echo "ERROR: httpx failed to installed"
    exit 1
else
    echo "INFO: httpx installed successfully"
fi

# -----------------------------------------------------------------------------
# STEP 10 — RUN UNIT TESTS
# -----------------------------------------------------------------------------
cd $AGNO_DIR
source .venv/bin/activate

echo "============= Running Unit Tests for $PACKAGE_NAME ================="

echo "INFO: The following test files are excluded due to unavailable or platform-incompatible dependencies:"
echo "INFO:   - test_client_deepcopy.py     (litellm — skipped for parity with x86)"
echo "INFO:   - test_docling_reader.py      (docling installed but skipped — torchvision native ops (nms) missing on ppc64le, causing docling import failures via transformers)"
echo "INFO:   - test_browserbase.py         (browserbase — skipped, playwright not available for Power architecture)"
echo "INFO:   - test_crawl4ai.py            (crawl4ai — skipped for parity with x86)"
echo "INFO:   - test_docling.py             (docling installed but skipped — torchvision native ops (nms) missing on ppc64le, causing docling import failures via transformers)"
echo "INFO:   - test_lancedb.py             (lancedb — skipped, lancedb not available for Power architecture)"

# libs/agno/tests/unit/tools/test_scrapegraph.py was skipped in (x86) agno github actions, included here since test cases are passing

ret=0
pytest libs/agno/tests/unit \
  --ignore=libs/agno/tests/unit/models/litellm \
  --ignore=libs/agno/tests/unit/reader/test_docling_reader.py \
  --ignore=libs/agno/tests/unit/tools/test_browserbase.py \
  --ignore=libs/agno/tests/unit/tools/test_crawl4ai.py \
  --ignore=libs/agno/tests/unit/tools/test_docling.py \
  --ignore=libs/agno/tests/unit/vectordb/test_lancedb.py || ret=$?

if [ $ret -ne 0 ]; then
    echo "ERROR: [$PACKAGE_NAME] Unit tests FAILED."
    exit 2
fi

echo ""
echo "============================================================"
echo "  SUCCESS: $PACKAGE_NAME $PACKAGE_VERSION — Build & Tests Passed"
echo "============================================================"
exit 0