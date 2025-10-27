# ----------------------------------------------------------------------------
#
# Package           : faiss
# Version           : 1.12.0
# Source repo       : https://github.com/facebookresearch/faiss.git
# Tested on         : RHEL 9.3
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

# Example container setup (for reference):
# podman create --name faiss-build -it registry.access.redhat.com/ubi9/ubi:latest bash
# podman start faiss-build
# podman exec -it faiss-build bash

# ----------------------------------------------------------------------------
# Install dependencies
# ----------------------------------------------------------------------------
dnf groupinstall -y "Development Tools"
dnf install -y \
    python3 python3-devel python3-pip \
    openblas-devel pcre2-devel cmake git \
    autoconf automake libtool bison

python3 -m pip install --upgrade pip setuptools wheel build numpy

# ----------------------------------------------------------------------------
# Repository Setup
# ----------------------------------------------------------------------------
mkdir -p /home/faiss_build && cd /home/faiss_build

# Clone FAISS and SWIG repositories
git clone https://github.com/facebookresearch/faiss.git
git clone https://github.com/swig/swig.git

# ----------------------------------------------------------------------------
# Build and Install SWIG (required for FAISS Python bindings)
# ----------------------------------------------------------------------------
cd swig
./autogen.sh
./configure
make -j$(nproc)
make install
cd ..

# ----------------------------------------------------------------------------
# Build FAISS
# ----------------------------------------------------------------------------
cd faiss
mkdir -p build && cd build

cmake .. \
    -DFAISS_ENABLE_PYTHON=ON \
    -DFAISS_ENABLE_GPU=OFF \
    -DBUILD_TESTING=OFF \
    -DPython_EXECUTABLE=$(which python3) \
    -DBLAS_LIBRARIES=/usr/lib64/libopenblas.so \
    -DCMAKE_BUILD_TYPE=Release

make -j$(nproc)

# ----------------------------------------------------------------------------
# Build Python Wheel
# ----------------------------------------------------------------------------
cd ./faiss/python

python3 -m build --wheel

# ----------------------------------------------------------------------------
# Verify the build
# ----------------------------------------------------------------------------
echo "Wheel built successfully. Listing wheel files:"
ls -lh dist/

# Optional: test installation
pip install dist/faiss-1.12.0-py3-none-any.whl
python3 -c "import faiss; print(faiss.__version__)"
