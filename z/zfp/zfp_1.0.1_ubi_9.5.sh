#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : zfp
# Version       : 1.0.1
# Source repo   : https://github.com/LLNL/zfp
# Tested on     : UBI:9.5
# Language      : C,Python
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Vinod K <Vinod.K1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=zfp
PACKAGE_VERSION=${1:-1.0.1}
PACKAGE_URL=https://github.com/LLNL/zfp
PACKAGE_DIR=zfp

echo "Installing dependencies...."
yum install -y wget gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran git make python3 python3-devel python3-pip openssl-devel cmake 

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

echo "Cloning and installing..."
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Checking Python version..."
PYTHON_VERSION=$(python3 -c "import sys; print('.'.join(map(str, sys.version_info[:2])))")
IFS='.' read -r MAJOR MINOR <<< "$PYTHON_VERSION"
if [[ "$MAJOR" -gt 3 ]] || { [[ "$MAJOR" -eq 3 ]] && [[ "$MINOR" -ge 12 ]]; }; then
    echo "Python version is >= 3.12, installing numpy 2.2.2..."
    python3 -m pip install cython numpy==2.2.2 wheel
else
    echo "Python version is < 3.12, installing numpy 1.23.5..."
    python3 -m pip install cython==0.29.36 numpy==1.23.5 wheel
fi

NUMPY_INCLUDE_DIR=$(python3 -c "import numpy; print(numpy.get_include())")

echo "Creating build directory..."
mkdir -p build
cd build
export CFLAGS="-fPIC -fopenmp"
export LDFLAGS="-fPIC -static-libgcc -static-libstdc++ -fopenmp -Wl,--whole-archive -lgomp -Wl,--no-whole-archive"

echo "Running CMake..."
echo "Running CMake with static linking..."
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_ZFPY=ON -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_INSTALL_PREFIX=$(pwd)/install \
    -DPYTHON_EXECUTABLE=$(which python3) \
    -DPYTHON_INCLUDE_DIR=$(python3 -c "import sysconfig; print(sysconfig.get_path('include'))") \
    -DPYTHON_LIBRARY=$(python3 -c "import sysconfig; print(sysconfig.get_config_var('LIBDIR'))") \
    -DNUMPY_INCLUDE_DIR=$NUMPY_INCLUDE_DIR \
    -DCMAKE_C_FLAGS="-fopenmp" \
    -DCMAKE_CXX_FLAGS="-fopenmp" \
    -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++ -fopenmp"

echo "Building zfp..."
make -j$(nproc)
make install 
export CMAKE_PREFIX_PATH=$(pwd)/install
cd ..

sed -i 's/), language_level = "3"]/)]/' setup.py

echo "installing..."
if ! python3 -m pip install . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass | Install_Success"
    exit 0
fi

#skipping test part as we don't have python tests to run.
