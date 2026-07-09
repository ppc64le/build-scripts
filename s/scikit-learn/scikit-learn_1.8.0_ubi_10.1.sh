#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scikit-learn
# Version       : 1.8.0
# Source repo   : https://github.com/scikit-learn/scikit-learn.git
# Tested on     : UBI 10.1
# Language      : Python, Cython, C++
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Shivansh Sharma <Shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -ex

PACKAGE_NAME=scikit-learn
PACKAGE_VERSION=${1:-1.8.0}
PACKAGE_URL=https://github.com/scikit-learn/scikit-learn.git
PACKAGE_DIR=scikit-learn
CURRENT_DIR=$(pwd)

yum install -y git make cmake wget python3.12 python3.12-devel python3.12-pip pkgconfig g++ gcc-c++ gcc-gfortran



#install openblas using the same method as openblas.sh
#clone and install openblas from source

OPENBLAS_VERSION="0.3.33"
OPENBLAS_URL="https://github.com/xianyi/OpenBLAS"

git clone -b v$OPENBLAS_VERSION $OPENBLAS_URL
cd OpenBLAS
git submodule update --init

# Setting the env variables for OpenBLAS build
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")
# See this workaround
# ( https://github.com/xianyi/OpenBLAS/issues/818#issuecomment-207365134 ).
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS
export USE_OPENMP=1
export PREFIX=/usr/local

declare -a build_opts
build_opts+=(USE_OPENMP=${USE_OPENMP})

if [ ! -z "$FFLAGS" ]; then
    # Don't use GNU OpenMP, which is not fork-safe
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi

build_opts+=(BINARY="64")
build_opts+=(DYNAMIC_ARCH=1)

# Set target platform-/CPU-specific options
export PLATFORM=$(uname -m)
case "${PLATFORM}" in
    ppc64le)
        build_opts+=(TARGET="POWER8")
        BUILD_BFLOAT16=1
        ;;
    s390x)
        build_opts+=(TARGET="Z14")
        ;;
    x86_64)
        # Oldest x86/x64 target microarch that has 64-bit extensions
        build_opts+=(TARGET="PRESCOTT")
        ;;
esac

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

#Build OpenBLAS
make -j8 ${build_opts[@]} \
     HOST=${HOST} CROSS_SUFFIX="${HOST}-" \
     CFLAGS="${CF}" FFLAGS="${FFLAGS}"

CFLAGS="${CF}" FFLAGS="${FFLAGS}" \
    make install PREFIX="${PREFIX}" ${build_opts[@]}

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64:/usr/local/lib
cd ..

echo "--------------------openblas installed-------------------------------"

cd $CURRENT_DIR

# Install Python dependencies
pip install numpy==2.2.6 cython meson-python ninja joblib threadpoolctl patchelf pytest

# Build and install SciPy from source to use custom OpenBLAS
SCIPY_VERSION="v1.17.1"
SCIPY_URL="https://github.com/scipy/scipy"
cd $CURRENT_DIR
git clone $SCIPY_URL
cd scipy
git checkout $SCIPY_VERSION
git submodule update --init

# Set environment variables for SciPy to find custom OpenBLAS
export OpenBLAS_HOME="/usr/local"
export PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig:${PKG_CONFIG_PATH}"

# Install additional SciPy build dependencies
pip install beniget==0.4.2.post1 Cython>=3.1.2 gast==0.6.0 meson==1.6.0 meson-python==0.17.1 packaging pybind11 pyproject-metadata pythran==0.17.0 setuptools==75.3.0 pooch build wheel

# Build and install SciPy from source
if ! pip install . --no-build-isolation; then
    echo "Failed to build SciPy from source with custom OpenBLAS"
    exit 1
fi

cd $CURRENT_DIR
# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

#build wheel 
python3.12 -m pip wheel -vv --no-build-isolation --no-deps .

# Install scikit-learn
if ! pip install --editable . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# test using pytest - set below flag as suggested in GitHub forums to resolve ImportPathMismatchError

export PY_IGNORE_IMPORTMISMATCH=1
if ! pytest sklearn/tests/test_random_projection.py; then
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
