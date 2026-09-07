#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scikit-learn
# Version       : 1.8.0
# Source repo   : https://github.com/scikit-learn/scikit-learn.git
# Tested on     : UBI 9.6
# Language      : Python, Cython, C++
# Ci-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Varsha Kumar <Varsha.Kumar@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=scikit-learn
PACKAGE_VERSION=${1:-1.8.0}
PACKAGE_URL=https://github.com/scikit-learn/scikit-learn.git
PACKAGE_DIR=scikit-learn

yum install -y --disablerepo="*rpmfusion*" \
    git gcc gcc-c++ make libtool cmake clang \
    openssl-devel bzip2-devel libffi-devel xz zlib-devel wget \
    python3.11 python3.11-devel python3.11-pip \
    gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran \
    libevent-devel openblas-devel

# scikit-learn 1.8.0 requires Python >= 3.11; skip gracefully for unsupported versions
PYTHON_VERSION=$(python3.11 --version 2>&1 | awk '{print $2}')
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
if [ "$PYTHON_MINOR" -lt 11 ]; then
    echo "------------------$PACKAGE_NAME:Build_not_supported------------------------------"
    echo "scikit-learn 1.8.0 requires Python >= 3.11, detected Python $PYTHON_VERSION"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Skip |  Unsupported_Python_Version"
    exit 0
fi

# Setup GCC toolset
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH

# Create Python 3.11 venv
python3.11 -m venv venv311
# shellcheck disable=SC1091
source venv311/bin/activate

# Upgrade pip & tools
pip install --upgrade pip setuptools wheel

# Clone OpenBLAS & build
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init
wget -q https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/python-ecosystem/o/openblas/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/v0.3.29/g" pyproject.toml

PREFIX=local/openblas
mkdir -p $PREFIX

export CF="-Wno-unused-parameter -Wno-old-style-declaration"
export USE_OPENMP=1
declare -a build_opts
build_opts+=(USE_OPENMP=${USE_OPENMP})
build_opts+=(BINARY=64 DYNAMIC_ARCH=1 TARGET="POWER9" INTERFACE64=0)
build_opts+=(NO_LAPACK=0 USE_THREAD=1 NUM_THREADS=8 NO_AFFINITY=1)

make -j$(nproc) ${build_opts[@]} CFLAGS="${CF}" prefix=$PREFIX
make install PREFIX="${PREFIX}" ${build_opts[@]}

OpenBLASInstallPATH=$(pwd)/$PREFIX
export LD_LIBRARY_PATH="${OpenBLASInstallPATH}/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="${OpenBLASInstallPATH}/lib/pkgconfig:$PKG_CONFIG_PATH"

OpenBLASConfigFile=$(find . -name OpenBLASConfig.cmake | head -n1)
OpenBLASPCFile=$(find . -name openblas.pc | head -n1)

[ -n "$OpenBLASConfigFile" ] && sed -i "/OpenBLAS_INCLUDE_DIRS/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" $OpenBLASConfigFile
[ -n "$OpenBLASConfigFile" ] && sed -i "/OpenBLAS_LIBRARIES/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" $OpenBLASConfigFile
[ -n "$OpenBLASPCFile" ] && sed -i "s|libdir=local/openblas/lib|libdir=${OpenBLASInstallPATH}/lib|" $OpenBLASPCFile
[ -n "$OpenBLASPCFile" ] && sed -i "s|includedir=local/openblas/include|includedir=${OpenBLASInstallPATH}/include|" $OpenBLASPCFile

cd ..

# clone source repository
git clone $PACKAGE_URL
cd $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init

# Install Python dependencies
pip install numpy==2.0.2 scipy cython meson-python ninja joblib threadpoolctl patchelf pytest


# Install
if ! pip install --editable . --no-build-isolation ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# test using pytest - set below flag as suggested in GitHub forums to resolve ImportPathMismatchError
export PY_IGNORE_IMPORTMISMATCH=1

# On Python 3.14, skip test_random_projection_numerical_consistency due to
# a known numpy broadcast incompatibility with float32/float64 component shapes
PYTHON_MINOR=$(python3.11 --version 2>&1 | awk '{print $2}' | cut -d. -f2)
PYTEST_ARGS=()
if [ "$PYTHON_MINOR" -ge 14 ]; then
    PYTEST_ARGS=(-k "not test_random_projection_numerical_consistency")
fi

if ! pytest sklearn/tests/test_random_projection.py "${PYTEST_ARGS[@]}"; then
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
