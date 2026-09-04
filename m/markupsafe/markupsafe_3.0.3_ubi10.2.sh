#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : markupsafe
# Version       : 3.0.3
# Source repo   : https://github.com/pallets/markupsafe
# Tested on     : UBI:10.2
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : tejasBadjateIBM <Tejas.Badjate@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=markupsafe
PACKAGE_VERSION=${1:-3.0.3}
PACKAGE_URL=https://github.com/pallets/markupsafe

yum install -y git gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran python3.14 python3.14-pip python3.14-devel gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel xz cmake zlib-devel pkgconfig 

export PATH=/opt/rh/gcc-toolset-15/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH 

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

git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION

#Installing all the requirements
python3.14 -m pip install pytest setuptools

if ! python3.14 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! python3.14 -m pytest ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi