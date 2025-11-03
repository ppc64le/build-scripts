#!/bin/bash
# -----------------------------------------------------------------------------
#
# Package           : faiss
# Version           : 1.12.0
# Source repo       : https://github.com/facebookresearch/faiss.git
# Tested on         : RHEL 9.6
# Language          : C++, Python
# Travis-Check      : True
# Script License    : Apache License Version 2.0
# Maintainer        : Madhur Gupta <madhur.gupta2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
set -e
# -----------------------------------------------------------------------------
# Set package version
# -----------------------------------------------------------------------------
VERSION=${1:-1.12.0}

# -----------------------------------------------------------------------------
# Install system dependencies
# -----------------------------------------------------------------------------
echo "Installing dependencies..."

dnf install -y \
    python3 python3-devel python3-pip \
    openblas-devel pcre2-devel cmake git \
    autoconf automake libtool g++ make wget bison

# -----------------------------------------------------------------------------
# Upgrade Python packaging tools
# -----------------------------------------------------------------------------
echo "Upgrading Python tools..."
python3 -m pip install --upgrade setuptools wheel build numpy

# -----------------------------------------------------------------------------
# Create build workspace
# -----------------------------------------------------------------------------
BUILD_DIR=/home/faiss_build
mkdir -p "${BUILD_DIR}" && cd "${BUILD_DIR}" || exit 1

# -----------------------------------------------------------------------------
# Check and install SWIG if not found
# -----------------------------------------------------------------------------
if ! command -v swig &> /dev/null; then
    echo "SWIG not found. Building SWIG from source..."
    if [ ! -d "swig" ]; then
        git clone https://github.com/swig/swig.git
    fi
    cd swig || exit 1
    ./autogen.sh
    ./configure
    make -j"$(nproc)"
    make install
    cd ..
else
    echo "SWIG already installed: $(swig -version | grep 'SWIG Version' | awk '{print $3}')"
fi

# Verify SWIG installation
swig -version || { echo "SWIG installation failed"; exit 1; }

# -----------------------------------------------------------------------------
# Clone FAISS repository
# -----------------------------------------------------------------------------
if [ ! -d "faiss" ]; then
    echo "Cloning FAISS repository..."
    git clone https://github.com/facebookresearch/faiss.git
fi

cd faiss || exit 1

# -----------------------------------------------------------------------------
# Build FAISS (CPU only)
# -----------------------------------------------------------------------------
mkdir -p build && cd build || exit 1

cmake .. \
    -DFAISS_ENABLE_PYTHON=ON \
    -DFAISS_ENABLE_GPU=OFF \
    -DBUILD_TESTING=OFF \
    -DPython_EXECUTABLE="$(which python3)" \
    -DBLAS_LIBRARIES="/usr/lib64/libopenblas.so" \
    -DCMAKE_BUILD_TYPE=Release

make -j"$(nproc)"

# -----------------------------------------------------------------------------
# Build Python wheel
# -----------------------------------------------------------------------------
cd ./faiss/python || exit 1
echo "Building Python wheel..."
python3 -m build --wheel

# -----------------------------------------------------------------------------
# Verify build output
# -----------------------------------------------------------------------------
echo "Listing built wheel files..."
ls -lh dist/

# -----------------------------------------------------------------------------
# Test FAISS installation (basic import test)
# -----------------------------------------------------------------------------
echo "Testing FAISS wheel installation..."
WHEEL_FILE=$(ls dist/faiss*.whl | head -n 1)
if [ -f "$WHEEL_FILE" ]; then
    pip install "$WHEEL_FILE"
    python3 -c "import faiss; print('FAISS version:', faiss.__version__)"
else
    echo "No wheel file found in dist/. Build may have failed."
    exit 1
fi

# -----------------------------------------------------------------------------
# Cleanup and summary
# -----------------------------------------------------------------------------
echo "FAISS ${VERSION} build and installation completed successfully!"
