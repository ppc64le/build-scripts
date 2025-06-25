#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scikit-learn
# Version       : 1.7.0
# Source repo   : https://github.com/scikit-learn/scikit-learn
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License 2.0
# Maintainer    : Manya Rusiya<Manya.Rusiya@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------



#!/bin/bash

# Don't exit on error
set -e

PACKAGE_NAME="scikit-learn"
PYTHON_VERSION="3.10.14"
SCIKIT_VERSION="1.7.0"
OPENBLAS_VERSION="v0.3.29"
GCC_TOOLSET_PATH="/opt/rh/gcc-toolset-13/root/usr"

echo "---- Installing Dependencies ----"
yum install -y git python-devel gcc gcc-c++ gzip tar make wget xz cmake yum-utils \
    openssl-devel openblas-devel bzip2-devel bzip2 zip unzip libffi-devel \
    zlib-devel autoconf automake libtool cargo pkgconf-pkg-config.ppc64le \
    info.ppc64le fontconfig.ppc64le fontconfig-devel.ppc64le sqlite-devel || true

dnf install -y gcc make zlib-devel bzip2 bzip2-devel  sqlite \
    sqlite-devel openssl-devel libffi-devel wget gcc-gfortran || true

yum install -y gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran \
    libevent-devel clang || true

export PATH="${GCC_TOOLSET_PATH}/bin:$PATH"
export LD_LIBRARY_PATH="${GCC_TOOLSET_PATH}/lib64:$LD_LIBRARY_PATH"

echo "---- Building Python $PYTHON_VERSION ----"
cd /usr/src || true
wget -q https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz || true
tar xzf Python-$PYTHON_VERSION.tgz || true
cd Python-$PYTHON_VERSION || true
./configure --enable-optimizations || true
make -j$(nproc) altinstall || true

/usr/local/bin/python3.10 --version || true
/usr/local/bin/python3.10 -m venv venv || true
source venv/bin/activate || true

echo "---- Upgrading pip and tools ----"
pip install -U pip setuptools wheel || true

echo "---- Cloning scikit-learn $SCIKIT_VERSION ----"
git clone https://github.com/scikit-learn/scikit-learn.git || true
cd scikit-learn || true
git checkout $SCIKIT_VERSION || true
git submodule update --init || true

echo "---- Building OpenBLAS $OPENBLAS_VERSION ----"
cd .. || true
git clone https://github.com/OpenMathLib/OpenBLAS.git || true
cd OpenBLAS || true
git checkout $OPENBLAS_VERSION || true
git submodule update --init || true

wget -q https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/python-ecosystem/o/openblas/pyproject.toml || true
sed -i "s/{PACKAGE_VERSION}/$OPENBLAS_VERSION/g" pyproject.toml || true

PREFIX=local/openblas
mkdir -p $PREFIX || true

export CF="-Wno-unused-parameter -Wno-old-style-declaration"
export USE_OPENMP=1
declare -a build_opts
build_opts+=(USE_OPENMP=${USE_OPENMP})
build_opts+=(BINARY=64 DYNAMIC_ARCH=1 TARGET="POWER9" INTERFACE64=0)
build_opts+=(NO_LAPACK=0 USE_THREAD=1 NUM_THREADS=8 NO_AFFINITY=1)

make -j$(nproc) ${build_opts[@]} CFLAGS="${CF}" prefix=$PREFIX || true
make install PREFIX="${PREFIX}" ${build_opts[@]} || true

OpenBLASInstallPATH=$(pwd)/$PREFIX
export LD_LIBRARY_PATH="${OpenBLASInstallPATH}/lib:$LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="${OpenBLASInstallPATH}/lib/pkgconfig:$PKG_CONFIG_PATH"

echo "---- Configuring OpenBLAS CMake and PKG files ----"
OpenBLASConfigFile=$(find . -name OpenBLASConfig.cmake | head -n1)
OpenBLASPCFile=$(find . -name openblas.pc | head -n1)

[ -n "$OpenBLASConfigFile" ] && sed -i "/OpenBLAS_INCLUDE_DIRS/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" $OpenBLASConfigFile || true
[ -n "$OpenBLASConfigFile" ] && sed -i "/OpenBLAS_LIBRARIES/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" $OpenBLASConfigFile || true
[ -n "$OpenBLASPCFile" ] && sed -i "s|libdir=local/openblas/lib|libdir=${OpenBLASInstallPATH}/lib|" $OpenBLASPCFile || true
[ -n "$OpenBLASPCFile" ] && sed -i "s|includedir=local/openblas/include|includedir=${OpenBLASInstallPATH}/include|" $OpenBLASPCFile || true

echo "---- Installing Python Dependencies ----"
cd ../scikit-learn || true
pip install numpy scipy cython meson-python ninja \
            joblib threadpoolctl patchelf pytest || true

pip install --no-binary :all: scipy || true
pip install --upgrade meson-python build || true
pip install ninja cython || true
pip install --editable . --no-build-isolation --verbose || true

echo "---- Running Test ----"
export PY_IGNORE_IMPORTMISMATCH=1
pytest sklearn/tests/test_random_projection.py || true

echo "---- Final Install Check ----"
if ! pip install --editable . --no-build-isolation --verbose --config-settings editable-verbose=true; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
else
    echo "------------------$PACKAGE_NAME:Install_success-------------------------------------"
fi

if ! pytest sklearn/tests/test_random_projection.py; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    exit 0
fi
