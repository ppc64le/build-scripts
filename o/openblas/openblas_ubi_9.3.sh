#!/bin/bash 
# -----------------------------------------------------------------------------
#
# Package         : OpenBLAS
# Version         : v0.3.32
# Source repo     : https://github.com/OpenMathLib/OpenBLAS
# Tested on       : UBI: 9.3
# Language        : C
# Ci-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Stuti Wali <Stuti.Wali@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -ex

# Variables
PACKAGE_NAME=OpenBLAS
PACKAGE_VERSION=${1:-v0.3.32}
PACKAGE_URL=https://github.com/OpenMathLib/OpenBLAS
OPENBLAS_VERSION=${PACKAGE_VERSION}
CURRENT_DIR=$(pwd)
PACKAGE_DIR=OpenBLAS
MAX_JOBS=${MAX_JOBS:-8}


echo "------------------------Installing dependencies-------------------"
yum install -y wget

# install core dependencies
yum install -y python python-pip python-devel  gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git make cmake binutils wget

python -m pip install --upgrade pip wheel

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
gcc --version

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# Clone the repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/openblas/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/$(echo $PACKAGE_VERSION | sed 's/^v//')/g" pyproject.toml
echo "--------------------------replaced version in pyproject.toml--------------------------"

export USE_OPENMP=1
export USE_THREAD=1
export NUM_THREADS=120
export TARGET=POWER9
export DYNAMIC_ARCH=1
export INTERFACE64=0
export BUILD_BFLOAT16=1
export NO_AFFINITY=1

# Fix flags
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS

# Remove problematic linker flag if present
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")

# -----------------------------------------------------------------------------
# Build
# -----------------------------------------------------------------------------
if ! make -j${MAX_JOBS} \
    TARGET=${TARGET} \
    BUILD_BFLOAT16=${BUILD_BFLOAT16} \
    BINARY=64 \
    USE_OPENMP=${USE_OPENMP} \
    USE_THREAD=${USE_THREAD} \
    NUM_THREADS=${NUM_THREADS} \
    DYNAMIC_ARCH=${DYNAMIC_ARCH} \
    INTERFACE64=${INTERFACE64} \
    NO_AFFINITY=${NO_AFFINITY} \
    CFLAGS="${CF}" ; then

    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    exit 1
fi

# -----------------------------------------------------------------------------
# Install OpenBLAS
# -----------------------------------------------------------------------------
echo "------------------------Installing OpenBLAS-------------------"

if ! make install PREFIX=${PREFIX} ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    exit 1
fi

# -----------------------------------------------------------------------------
# Library path setup
# -----------------------------------------------------------------------------
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${PREFIX}/lib64:${PREFIX}/lib

# -----------------------------------------------------------------------------
# Python package install (from original script)
# -----------------------------------------------------------------------------
echo "------------------------Installing Python package-------------------"

if ! pip install . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:Python_Install_fails-------------------------------------"
    exit 1
fi

# -----------------------------------------------------------------------------
# Run tests
# -----------------------------------------------------------------------------
echo "------------------------Running tests-------------------"

if !(make -C utest all); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    exit 0
fi
