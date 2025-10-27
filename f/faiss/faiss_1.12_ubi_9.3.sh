# ----------------------------------------------------------------------------
#
# Package           : faiss
# Version           : 1.12.0
# Source repo       : https://github.com/facebookresearch/faiss.git
# Tested on         : RHEL 9.6
# Script License    : Apache License Version 2.0
# Maintainer        : Madhur Gupta <madhur.gupta2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such cases, please
#             contact the "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

#!/bin/bash
# ----------------------------------------------------------------------------
# Install system dependencies
# ----------------------------------------------------------------------------
dnf -y groupinstall "Development Tools"
dnf -y install \
    python3 python3-devel python3-pip \
    openblas-devel pcre2-devel cmake git \
    autoconf automake libtool bison flex \
    make gcc gcc-c++ m4 patch \
    wget tar unzip which file

# ----------------------------------------------------------------------------
# Upgrade Python packaging tools
# ----------------------------------------------------------------------------
python3 -m pip install --upgrade pip setuptools wheel build numpy

# ----------------------------------------------------------------------------
# Create build directory
# ----------------------------------------------------------------------------
mkdir -p /home/faiss_build && cd /home/faiss_build

# ----------------------------------------------------------------------------
# Check if SWIG is installed, otherwise build it
# ----------------------------------------------------------------------------
if ! command -v swig &> /dev/null; then
    echo "SWIG not found. Building SWIG from source..."
    if [ ! -d "swig" ]; then
        git clone https://github.com/swig/swig.git
    fi
    cd swig
    ./autogen.sh
    ./configure
    make -j"$(nproc)"
    make install
    cd ..
else
    echo "SWIG already installed: $(swig -version | grep 'SWIG Version' | awk '{print $3}')"
fi

# Verify SWIG
swig -version || { echo "SWIG installation failed"; exit 1; }

# ----------------------------------------------------------------------------
# Clone FAISS repository
# ----------------------------------------------------------------------------
if [ ! -d "faiss" ]; then
    git clone https://github.com/facebookresearch/faiss.git
fi

# ----------------------------------------------------------------------------
# Build FAISS from source
# ----------------------------------------------------------------------------
cd faiss
mkdir -p build && cd build

cmake .. \
    -DFAISS_ENABLE_PYTHON=ON \
    -DFAISS_ENABLE_GPU=OFF \
    -DBUILD_TESTING=OFF \
    -DPython_EXECUTABLE="$(which python3)" \
    -DBLAS_LIBRARIES="/usr/lib64/libopenblas.so" \
    -DCMAKE_BUILD_TYPE=Release

make -j"$(nproc)"

# ----------------------------------------------------------------------------
# Build Python Wheel
# ----------------------------------------------------------------------------
cd ../faiss/python

python3 -m build --wheel

# ----------------------------------------------------------------------------
# Verify the build
# ----------------------------------------------------------------------------
echo "Wheel built successfully. Listing wheel files:"
ls -lh dist/

# Optional: test installation (uncomment to enable and change the wheel file name if necessary)
# pip install dist/faiss-1.12.0-py3-none-any.whl
# python3 -c "import faiss; print('FAISS version:', faiss.__version__)"