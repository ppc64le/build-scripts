#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : OpenBLAS
# Version          : v0.3.33
# Source repo      : https://github.com/OpenMathLib/OpenBLAS
# Tested on        : UBI:10.2
# Language         : C
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Yogita Kulkarni <Yogita.Kulkarni1@ibm.com>
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
PACKAGE_VERSION=${1:-v0.3.33}
PACKAGE_URL=https://github.com/OpenMathLib/OpenBLAS
OPENBLAS_VERSION=${PACKAGE_VERSION}
CURRENT_DIR=$(pwd)
PACKAGE_DIR=OpenBLAS
SCRIPT_PATH=$(dirname "$(realpath "$0")")
MAX_JOBS=${MAX_JOBS:-8}


echo "------------------------Installing dependencies-------------------"
# install core dependencies (Python packages first for create_wheel_wrapper compatibility)
yum install -y python3.14 python3.14-pip python3.14-devel \
    gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran \
    gcc-toolset-15-binutils gcc-toolset-15-binutils-devel git make cmake binutils wget

python3.14 -m pip install --upgrade pip wheel build "setuptools==79.0.1"

if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi
echo "Using gcc: $(gcc --version | head -1)"

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

# Clone the repository
cd "$CURRENT_DIR"
git clone $PACKAGE_URL $PACKAGE_DIR
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION
git submodule update --init

if [[ -f "${SCRIPT_PATH}/pyproject.toml" ]]; then
    cp "${SCRIPT_PATH}/pyproject.toml" .
else
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/openblas/pyproject.toml
fi
CLEAN_VERSION=$(echo "$PACKAGE_VERSION" | sed 's/^v//')
sed -i "s/{PACKAGE_VERSION}/$CLEAN_VERSION/g" pyproject.toml

# Create the local directory structure expected by pyproject.toml
mkdir -p local/openblas
PREFIX=local/openblas

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
# python3.14 package install (from original script)
# -----------------------------------------------------------------------------
echo "------------------------Installing python3.14 package-------------------"

if ! pip install . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:python3.14_Install_fails-------------------------------------"
    exit 1
fi

# -----------------------------------------------------------------------------
# Run tests
# -----------------------------------------------------------------------------
echo "------------------------Running tests-------------------"

if !(make -C utest all); then
    echo "------------------$PACKAGE_NAME:install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi