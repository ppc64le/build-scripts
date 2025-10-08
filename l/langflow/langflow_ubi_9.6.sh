#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : langflow
# Version       : 1.6.0
# Source repo   : https://github.com/langflow-ai/langflow.git
# Tested on     : UBI:9.6
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Aastha Sharma <aastha.sharma4@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=langflow
PACKAGE_VERSION=${1:-1.6.0}
PACKAGE_URL=https://github.com/langflow-ai/langflow.git
PACKAGE_DIR=langflow
CURRENT_DIR=$(pwd)

# -----------------------------------------------------------------------------
# Install required system packages (YUM)
# -----------------------------------------------------------------------------

yum install -y git make wget openssl-devel bzip2-devel libffi-devel zlib-devel python3.12-devel python3.12-pip cmake openblas-devel gcc-toolset-13 m4 automake libtool libjpeg-devel zlib-devel libpng-devel freetype-devel gcc-toolset-13-binutils

# -----------------------------------------------------------------------------
# Enable GCC 13 (from gcc-toolset-13)
# -----------------------------------------------------------------------------

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# -----------------------------------------------------------------------------
# Install Python packages 
# -----------------------------------------------------------------------------
python3.12 -m pip install pytest anyio orjson asgi_lifespan blockbuster dotenv fastapi httpx
python3.12 -m pip install cython setuptools wheel pytest plotly
python3.12 -m pip install six numpy pandas scipy matplotlib  scikit-learn graphviz uv 

echo " ------------------------------ Installing Swig ------------------------------ "
git clone https://github.com/nightlark/swig-pypi.git
cd swig-pypi
pip3.12 install .
cd $CURRENT_DIR
echo " ------------------------------ Swig Installed Successfully ------------------------------ "

echo "----------------------bison installing---------------------------------"
wget https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.gz
tar -xvf bison-3.8.2.tar.gz
cd bison-3.8.2
echo "Configuring bison installation..."
./configure --prefix=/usr/local
echo "Compiling the source code bison..."
make -j$(nproc)
echo "Installing bison..."
make install
cd $CURRENT_DIR
echo " ------------------------------ bison Installed Successfully ------------------------------ "

echo "------------------------flex installing-----------------------------"
wget https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz
tar -xvf flex-2.6.4.tar.gz
cd flex-2.6.4
echo "Configuring flex installation..."
./configure --prefix=/usr/local
echo "Compiling the source code for flex..."
make -j$(nproc)
echo "Installing flex..."
make install
cd $CURRENT_DIR
echo " ------------------------------ flex Installed Successfully ------------------------------ "

echo "--------------------- gflags installing --------------------------"
git clone https://github.com/gflags/gflags.git
cd gflags
mkdir build && cd build
echo "Running cmake to configure the build..."
cmake ..
echo "Compiling the source code gflags..."
make -j$(nproc)
echo "Installing gflags..."
make install
cd $CURRENT_DIR
echo " ------------------------------ gfags Installed Successfully ------------------------------ "

echo "--------------------- faiss installing --------------------------"
git clone https://github.com/facebookresearch/faiss.git
cd faiss
rm -rf build && mkdir build && cd build

# reenable gcc compiler
export LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export CC=$(which gcc)
export CXX=$(which g++)

# Set correct Python vars for CMake's FindPython
export Python3_EXECUTABLE=$(which python3.12)
export Python3_INCLUDE_DIR=$(python3.12 -c "from sysconfig import get_path; print(get_path('include'))")
export Python3_LIBRARY=/usr/lib64/libpython3.12.so
export Python3_NumPy_INCLUDE_DIR=$(python3.12 -c "import numpy; print(numpy.get_include())")
source /opt/rh/gcc-toolset-13/enable

cmake \
  -DFAISS_ENABLE_PYTHON=ON \
  -DFAISS_ENABLE_GPU=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DPython3_EXECUTABLE=$(which python3.12) \
  -DPython3_INCLUDE_DIR=$(python3.12 -c "from sysconfig import get_path; print(get_path('include'))") \
  -DPython3_LIBRARY=/usr/lib64/libpython3.12.so \
  -DPython3_NumPy_INCLUDE_DIR=$(python3.12 -c "import numpy; print(numpy.get_include())") \
  ..

make -j$(nproc) swigfaiss

# Install the Python bindings
cd faiss/python
python3.12 setup.py install
cd $CURRENT_DIR

# -----------------------------------------------------------------------------
#clone and install package
# -----------------------------------------------------------------------------
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

# -----------------------------------------------------------------------------
# install langflow
# -----------------------------------------------------------------------------
if ! python3.12 -m pip install . --no-deps; then
    echo "------------------$PACKAGE_NAME:Build_Fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Skipping tests: uv.lock is broken, requires auth setup, and includes packages not supported on Power architecture
