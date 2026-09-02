#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : zstd
# Version       : v1.5.7.2
# Source repo   : https://github.com/sergey-dryabzhinsky/python-zstd.git
# Tested on     : UBI:10.2
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : tejasBadjateIBM <Tejas.Badjate@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

# Variables
PACKAGE_NAME=zstd
PACKAGE_VERSION=${1:-v1.5.7.2}
PACKAGE_URL=https://github.com/sergey-dryabzhinsky/python-zstd.git
PACKAGE_DIR=python-zstd

# Install dependencies and tools.
yum install -y git wget  python3.14-devel python3.14-pip openssl-devel cmake libzstd.ppc64le
python3.14 -m pip install --upgrade pip setuptools wheel pytest

yum install gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ -y

# ---------------------------------------------------------------------------
# Activate GCC Toolset 15 (SCL removed in UBI 10 — use PATH export)
# ---------------------------------------------------------------------------
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"

export CC="/opt/rh/gcc-toolset-15/root/usr/bin/gcc"
export CXX="/opt/rh/gcc-toolset-15/root/usr/bin/g++"

echo "-------------------------------------------------------------Installing Openblas ---------------------------------------------------------"

git clone -b v0.3.33 https://github.com/xianyi/OpenBLAS
cd OpenBLAS
git submodule update --init
SRC_DIR=$(pwd)

# Set pip config
python3.14 -m pip config set global.index-url https://pypi.python.org/simple
python3.14 -m pip config set global.no-index false

# Install prerequisite wheels
python3.14 -m pip install setuptools

# Setting the environment variables
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")

# See this workaround:
# https://github.com/xianyi/OpenBLAS/issues/818#issuecomment-207365134
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS
export USE_OPENMP=1

# Set installation path
export PREFIX=${SRC_DIR}/local/openblas

# Build options
build_opts=()
build_opts+=(USE_OPENMP=${USE_OPENMP})

if [ -n "${FFLAGS}" ]; then
    # Don't use GNU OpenMP, which is not fork-safe
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi

build_opts+=(BINARY="64")
build_opts+=(DYNAMIC_ARCH=1)

# Set target platform-/CPU-specific options
# Only setting option for x86 CPU platform
build_opts+=(TARGET="PRESCOTT")

# Placeholder for future builds that may include ILP64 variants.
build_opts+=(INTERFACE64=0)
build_opts+=(SYMBOLSUFFIX="")

# Build LAPACK
build_opts+=(NO_LAPACK=0)

# Enable threading
build_opts+=(USE_THREAD=1)
build_opts+=(NUM_THREADS=8)

# Disable CPU/memory affinity handling to avoid problems with NumPy and R
build_opts+=(NO_AFFINITY=1)

# Build
make -j8 ${build_opts[@]} \
     HOST=${HOST} CROSS_SUFFIX="${HOST}-" \
     CFLAGS="${CF}" FFLAGS="${FFLAGS}"

# Install OpenBLAS to PREFIX
CFLAGS="${CF}" FFLAGS="${FFLAGS}" \
    make install PREFIX="${PREFIX}" "${build_opts[@]}"

cd ..
echo ""-------------------------------------------------------------Installed Openblas ---------------------------------------------------------""


#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_DIR
git checkout $PACKAGE_VERSION
git submodule update --init

#install
if ! python3.14 setup.py install ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#test
if ! python3.14 -m pytest; then
    echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi


