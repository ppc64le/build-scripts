#!/bin/bash 
# -----------------------------------------------------------------------------
#
# Package         : OpenBLAS
# Version         : v0.3.33
# Source repo     : https://github.com/OpenMathLib/OpenBLAS
# Tested on       : UBI: 10.1
# Language        : C
# Ci-Check    : True
# Script License  : Apache License, Version 2 or later
# Maintainer      : Shivansh Sharma <shivansh.s11@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             it may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -ex

# Variables
PACKAGE_NAME=OpenBLAS
PACKAGE_VERSION=${1:-v0.3.33}
PACKAGE_URL="https://github.com/xianyi/OpenBLAS"
OPENBLAS_VERSION=${PACKAGE_VERSION}
CURRENT_DIR=$(pwd)
PACKAGE_DIR=OpenBLAS

echo "Installing dependencies..."
yum install -y git make cmake wget python3.12 python3.12-devel python3.12-pip pkgconfig g++ gcc-c++ gcc-gfortran


git clone -b $PACKAGE_VERSION $PACKAGE_URL
cd OpenBLAS
git submodule update --init
SRC_DIR=$(pwd)

#Set pip config
python3.12 -m pip config set global.index-url https://pypi.python.org/simple
python3.12 -m pip config set global.no-index false

#Install pre requisite wheels
python3.12 -m pip install setuptools
#Setting the env variables
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")

# See this workaround
# ( https://github.com/xianyi/OpenBLAS/issues/818#issuecomment-207365134 ).
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS
export USE_OPENMP=1

#TODO: Pass path
export PREFIX=${SRC_DIR}/local/openblas

#build options
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
#only seeting option for x86-cpu platform
build_opts+=(TARGET="PRESCOTT")

# Placeholder for future builds that may include ILP64 variants.
build_opts+=(INTERFACE64=0)
build_opts+=(SYMBOLSUFFIX="")

# Build LAPACK.
build_opts+=(NO_LAPACK=0)

# Enable threading. This can be controlled to a certain number by
# setting OPENBLAS_NUM_THREADS before loading the library.
build_opts+=(USE_THREAD=1)
build_opts+=(NUM_THREADS=8)

# Disable CPU/memory affinity handling to avoid problems with NumPy and R
build_opts+=(NO_AFFINITY=1)

#Build:-
make -j8 ${build_opts[@]} \
     HOST=${HOST} CROSS_SUFFIX="${HOST}-" \
     CFLAGS="${CF}" FFLAGS="${FFLAGS}"

# Install OpenBLAS to PREFIX
CFLAGS="${CF}" FFLAGS="${FFLAGS}" \
    make install PREFIX="${PREFIX}" "${build_opts[@]}"

# Verify installation succeeded
[ -d "${PREFIX}" ] || { echo "ERROR: make install failed — PREFIX dir not created: ${PREFIX}"; exit 1; }

# Prepare package structure
#install pyproject.toml
wget -O pyproject.toml https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/main/o/openblas/pyproject_v0.3.33.toml
sed -i s/{PACKAGE_VERSION}/$PACKAGE_VERSION/g pyproject.toml

# Finalize OpenBLAS package layout
touch "${PREFIX}/__init__.py"
rm -rf "${PREFIX}/bin"


#building wheel
python3.12 -m pip wheel -v . --no-build-isolation --no-deps

echo "------------------------Installing Python package-------------------"

if ! python3.12 -m pip install . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:Python_Install_fails-------------------------------------"
    exit 1
fi

# Run tests

if ! make -C utest all; then
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


