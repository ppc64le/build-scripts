#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : pyzmq
# Version          : v26.3.0
# Source repo      : https://github.com/zeromq/pyzmq.git
# Tested on        : UBI:9.5
# Language         : Python
# Travis-Check     : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinod.K1 <Vinod.K1@ibm.com>
#
# Disclaimer       : This script has been tested in root mode on given
# ==========         platform using the mentioned version of the package.
#                    It may not work as expected with newer versions of the
#                    package and/or distribution. In such case, please
#                    contact "Maintainer" of this script.
#
# ---------------------------------------------------------------------------

# Variables
PACKAGE_NAME=pyzmq
PACKAGE_VERSION=${1:-v26.3.0}
PACKAGE_URL=https://github.com/zeromq/pyzmq.git
PACKAGE_DIR=pyzmq
CURRENT_DIR="${PWD}"

# Install dependencies
yum install -y git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran \
    cmake make wget openssl-devel bzip2-devel glibc-static libstdc++-static libffi-devel \
    zlib-devel python-devel python-pip pkg-config automake autoconf libtool

source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Clone and build libzmq
git clone https://github.com/zeromq/libzmq.git
cd libzmq
mkdir -p build && cd build
cmake .. \
    -DBUILD_SHARED=OFF \
    -DBUILD_STATIC=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DENABLE_DRAFTS=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++" \
    -DCMAKE_EXE_LINKER_FLAGS="-static"
make -j$(nproc)
make install
cd ../..

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

pip install cmake setuptools wheel cython cffi pytest tornado pytest-asyncio pytest-timeout scikit_build_core build ninja gevent

# Set environment variables for static linking
export CMAKE_PREFIX_PATH="/usr/local"
export ZMQ_STATIC=1
export ZMQ_PREFIX=/usr/local
export ZMQ_ENABLE_DRAFTS=1
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig"
export LDFLAGS="-L/usr/local/lib -l:libzmq.a -lstdc++ -static -static-libgcc -static-libstdc++ -lc -lrt -lpthread -ldl"
export CFLAGS="-fPIC"


#install
if ! pip install --editable . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi
# Run tests
if ! pytest -v --timeout=60 --capture=no -p no:warnings --ignore=tests/test_draft.py; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
fi

# Building wheel with script itself as it needs to locate the libzmq target file 
if ! python3 -m build --wheel --no-isolation --outdir="$CURRENT_DIR"; then
    echo "------------------$PACKAGE_NAME: Wheel Build Failed ---------------------"
    exit 2
else
    echo "------------------$PACKAGE_NAME: Wheel Build Success -------------------------"
    exit 0
fi
