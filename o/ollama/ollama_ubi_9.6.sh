#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package         : Ollama (Power10 optimized)
# Version         : v0.12.10
# Source repo     : https://github.com/ollama/ollama
# Tested on       : UBI:9.6
# Language        : Go, C, Python
# Travis-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Shalini Salomi Bodapati <Shalini-Salomi-Bodapati@ibm.com>
# -----------------------------------------------------------------------------


set -e

# Variables
PACKAGE_NAME=ollama
PACKAGE_VERSION=${1:-v0.12.10}
PACKAGE_URL=https://github.com/ollama/ollama
OLLAMA_VERSION=${PACKAGE_VERSION}
CURRENT_DIR=$(pwd)
PACKAGE_DIR=ollama

echo "------------------------Installing dependencies-------------------"

# install core dependencies
yum install -y python python-pip python-devel  gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git make cmake binutils wget patch

python -m pip install --upgrade pip wheel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
gcc --version

echo "**** Checking GCC version..."
gcc -v || true

# -----------------------------------------------------------------------------
# Download Go
# -----------------------------------------------------------------------------
GO_VERSION="1.24.1"
GO_TAR="go${GO_VERSION}.linux-ppc64le.tar.gz"
GO_DIR="go"

if [ ! -d "${GO_DIR}" ]; then
    echo "**** Downloading Go ${GO_VERSION}..."
    wget -q https://go.dev/dl/${GO_TAR}
    echo "**** Extracting Go binary..."
    tar xzf ${GO_TAR}
else
    echo "**** Go already extracted, skipping..."
fi

export PATH="$(pwd)/go/bin:$PATH"

# -----------------------------------------------------------------------------
# Clone and patch Ollama
# -----------------------------------------------------------------------------

echo "**** Cloning Ollama repository..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "**** Downloading Power10 patches..."
wget -q -O build_power.patch https://github.com/ollama/ollama/commit/67b8d3c817fbdc57fedad9b032d0efc10285220a.patch
wget -q -O set_threads_env.patch https://github.com/ollama/ollama/commit/1364a887a1d7c25522e9c921d55e50a6aea44964.patch
wget -q -O enable_mma.patch https://github.com/ollama/ollama/commit/fe924304809ae8e6bd6957b0ce5759eb2a796d42.patch

echo "** Applying Patches..."

patch -p1 < build_power.patch
patch -p1 < set_threads_env.patch
patch -p1 < enable_mma.patch

# -----------------------------------------------------------------------------
# Build Ollama
# -----------------------------------------------------------------------------
echo "**** Building Ollama with CMake..."
cmake -B build
cmake --build build -j$(nproc)

export CGO_LDFLAGS="-L$(pwd)/build/lib/ollama/ -lggml-cpu-power10"

echo "**** Building Ollama binary with Go..."
../go/bin/go build --tags ppc64le.power10 -o ollama .


# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------
cd ../..
echo "**** Cleaning temporary files..."
rm -f go1.24.1.linux-ppc64le.tar.gz
echo "**** Done! Ollama Power10 wheel ready."

cd ${CURRENT_DIR}
if ls *.whl 1>/dev/null 2>&1; then
    echo "Wheel file already exist in the current directory:"
    ls *.whl
else
    #Navigating to the package directory to build wheel
    if [ -d "${PACKAGE_DIR}" ]; then
        echo "Navigating to the package directory: ${PACKAGE_DIR}"
        cd "$PACKAGE_DIR"
    else
        echo "package_dir not found, Navigating to package_name: $package_name"
        cd "$package_name"
    fi

    echo "=============== Building wheel =================="

    # Attempt to build the wheel without isolation
    if ! python -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"; then
        echo "============ Wheel Creation Failed for Python $PYTHON_VERSION (without isolation) ================="
        echo "Attempting to build with isolation..."

        # Attempt to build the wheel without isolation
        if ! python -m build --wheel --outdir="$CURRENT_DIR/"; then
            echo "============ Wheel Creation Failed for Python $PYTHON_VERSION ================="
            EXIT_CODE=1
        fi
    fi
fi

