#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : sdg_hub
# Version       : v0.6.1
# Source repo   :
# Tested on     : UBI:9.6
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2.0
# Maintainer    : Bhagyashri Gaikwad <Bhagyashri.Gaikwad2@ibm.com> 
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
set -ex

# ================================================
# Variables
# ================================================
PACKAGE_NAME="sdg_hub"
PACKAGE_ORG="Red-Hat-AI-Innovation-Team"
PACKAGE_VERSION="v0.6.1"
PACKAGE_URL="https://github.com/${PACKAGE_ORG}/${PACKAGE_NAME}.git"
PACKAGE_DIR="${PACKAGE_NAME}"
PYARROW_VERSION="22.0.0"

OS_NAME=$(grep ^PRETTY_NAME /etc/os-release | cut -d= -f2)
SOURCE="Github"

# ================================================
# Dependency Installation
# ================================================
echo "Installing system dependencies..."

dnf install -y git python3.11 python3.11-devel python3.11-pip \
    gcc gcc-c++ make cmake wget

echo "Upgrading pip, uv, and build tools..."
python3.11 -m pip install --upgrade pip setuptools wheel build uv

echo "Installing Python dependencies for PyArrow build..."
python3.11 -m pip install "Cython>=3.1,<3.3" numpy

export PATH=$PATH:/usr/local/bin
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

# ================================================
# Clone SDG HUB Repository
# ================================================
echo "Cloning SDG Hub repository..."

if [[ "$PACKAGE_URL" == *github.com* ]]; then
    if [ -d "$PACKAGE_DIR" ]; then
        cd "$PACKAGE_DIR"
    else
        if ! git clone "$PACKAGE_URL" "$PACKAGE_DIR"; then
            echo "------------------$PACKAGE_NAME:clone_fails---------------------------------------"
            echo "$PACKAGE_URL $PACKAGE_NAME"
            echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | $OS_NAME | $SOURCE | Fail | Clone_Fails"
            exit 1
        fi
        cd "$PACKAGE_DIR"
        git checkout "$PACKAGE_VERSION"
    fi
else
    echo "Invalid PACKAGE_URL"
    exit 1
fi

cd ..

# ================================================
# Build PyArrow (ORC Disabled)
# ================================================
echo "==================== PYARROW BUILD START ===================="
echo "Building PyArrow $PYARROW_VERSION from source (ORC OFF)..."

rm -rf arrow
git clone https://github.com/apache/arrow.git
cd arrow
git fetch --all --tags
git checkout apache-arrow-${PYARROW_VERSION}
git submodule update --init --recursive

cd cpp
rm -rf release
mkdir release && cd release

echo "[POWER] Running CMake for Arrow C++ (ORC OFF)..."

cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DARROW_PYTHON=ON \
      -DARROW_ORC=OFF \
      -DARROW_PARQUET=ON \
      -DARROW_DATASET=ON \
      -DARROW_CSV=ON \
      -DARROW_JSON=ON \
      -DARROW_FILESYSTEM=ON \
      -DARROW_WITH_LZ4=ON \
      -DARROW_WITH_ZSTD=ON \
      -DARROW_WITH_SNAPPY=ON \
      -DARROW_WITH_ZLIB=ON \
      -DARROW_BUILD_TESTS=OFF \
      -DARROW_DEPENDENCY_SOURCE=BUNDLED \
      -DProtobuf_SOURCE=BUNDLED \
      -DThrift_SOURCE=BUNDLED \
      ..

echo "[POWER] Building Arrow C++..."
make -j"$(nproc)"

echo "[POWER] Installing Arrow C++..."
make install

export ARROW_HOME=/usr/local
export CMAKE_PREFIX_PATH=/usr/local
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH

cd ../../python

echo "[POWER] Building PyArrow wheel..."
python3.11 -m pip wheel . --no-deps \
  --config-settings=build_ext_args="--bundle-arrow-cpp" \
  -vvv

mkdir -p ~/wheelhouse
cp -v *.whl ~/wheelhouse/

echo "==================== PYARROW BUILD COMPLETE ===================="

cd ../..

# ================================================
# SDG Hub Installation
# ================================================
echo "Installing SDG Hub with uv..."

cd "$PACKAGE_DIR"

# Install PyArrow built from source
python3.11 -m uv pip install ~/wheelhouse/pyarrow-${PYARROW_VERSION}-*.whl

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# Install SDG Hub with dev extras
python3.11 -m uv pip install .[dev]


python3.11 -m pip install pytest
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH
echo "Running tests..."

if ! pytest; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL |  $PACKAGE_VERSION | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi