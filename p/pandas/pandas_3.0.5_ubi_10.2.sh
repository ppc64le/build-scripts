#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pandas
# Version       : v3.0.5
# Source repo   : https://github.com/pandas-dev/pandas.git
# Tested on     : UBI:10.2
# Language      : Python, C, Cython, HTML
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
PACKAGE_NAME=pandas
PACKAGE_VERSION=${1:-v3.0.5}
PACKAGE_URL=https://github.com/pandas-dev/pandas.git
PACKAGE_DIR=pandas
CURRENT_DIR="${PWD}"
WHEEL_DIR="${CURRENT_DIR}/wheels"

mkdir -p "$WHEEL_DIR"

# Install system dependencies including SQLite and LZMA libraries
yum install -y git gcc gcc-c++ python3.14 python3.14-pip python3.14-devel \
    gzip tar make wget xz cmake yum-utils openssl-devel \
    bzip2-devel bzip2 zip unzip libffi-devel zlib-devel autoconf \
    automake libtool cargo pkgconf-pkg-config.ppc64le info.ppc64le fontconfig.ppc64le \
    fontconfig-devel.ppc64le sqlite-devel

# -----------------------------------------------------------------------------
# OpenBLAS
# -----------------------------------------------------------------------------

echo " --------------------------------------------------- OpenBlas Installing --------------------------------------------------- "

# OpenBLAS version and source
OPENBLAS_VERSION=v0.3.33
OPENBLAS_URL=https://github.com/OpenMathLib/OpenBLAS

# Clone OpenBLAS
git clone -b "${OPENBLAS_VERSION}" "${OPENBLAS_URL}"
cd OpenBLAS
git submodule update --init
SRC_DIR=$(pwd)

# Set pip config
python3.14 -m pip config set global.index-url https://pypi.python.org/simple
python3.14 -m pip config set global.no-index false

# Install prerequisites
python3.14 -m pip install setuptools

# Remove problematic linker flag
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")
export LDFLAGS

# Compiler flags
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS

export USE_OPENMP=1

# Installation prefix
export PREFIX="${SRC_DIR}/local/openblas"

# Build options
build_opts=()

build_opts+=(USE_OPENMP=${USE_OPENMP})
build_opts+=(BINARY="64")
build_opts+=(DYNAMIC_ARCH=1)

# ppc64le / POWER platform
build_opts+=(TARGET="POWER9")

# LP64 interface
build_opts+=(INTERFACE64=0)
build_opts+=(SYMBOLSUFFIX="")

# Build LAPACK
build_opts+=(NO_LAPACK=0)

# Enable threading
build_opts+=(USE_THREAD=1)
build_opts+=(NUM_THREADS=8)

# Disable CPU affinity
build_opts+=(NO_AFFINITY=1)

# Handle Fortran flags
if [ -n "${FFLAGS}" ]; then
    # Don't use GNU OpenMP, which is not fork-safe
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi

# Build OpenBLAS
make -j8 "${build_opts[@]}" \
    CFLAGS="${CF}" \
    FFLAGS="${FFLAGS}"

# Install OpenBLAS
make install \
    PREFIX="${PREFIX}" \
    "${build_opts[@]}" \
    CFLAGS="${CF}" \
    FFLAGS="${FFLAGS}"

# Verify installation
[ -d "${PREFIX}" ] || {
    echo "ERROR: make install failed — PREFIX directory was not created: ${PREFIX}"
    exit 1
}

# Set OpenBLAS paths
export OPENBLAS_HOME="${PREFIX}"
export LD_LIBRARY_PATH="${OPENBLAS_HOME}/lib:${LD_LIBRARY_PATH}"
export LIBRARY_PATH="${OPENBLAS_HOME}/lib:${LIBRARY_PATH}"
export CPATH="${OPENBLAS_HOME}/include:${CPATH}"
export PKG_CONFIG_PATH="${OPENBLAS_HOME}/lib/pkgconfig:${PKG_CONFIG_PATH}"
export CMAKE_PREFIX_PATH="${OPENBLAS_HOME}:${CMAKE_PREFIX_PATH}"

# Prepare Python package structure
wget https://raw.githubusercontent.com/i-wheels-cpd/build-scripts/refs/heads/main/o/openblas/pyproject.toml

sed -i "s/{PACKAGE_VERSION}/${OPENBLAS_VERSION}/g" pyproject.toml

touch "${PREFIX}/__init__.py"
rm -rf "${PREFIX}/bin"

echo " --------------------------------------------------- OpenBLAS Successfully Installed --------------------------------------------------- "

cd $CURRENT_DIR

# Clone the pandas repository and checkout the required version
git clone $PACKAGE_URL
cd $PACKAGE_DIR/
git checkout $PACKAGE_VERSION

# Initialize and update submodules
git submodule update --init --recursive

# Install dependencies
python3.14 -m pip install --upgrade pip
python3.14 -m pip install pytest hypothesis build meson meson-python
python3.14 -m pip install cython
python3.14 -m pip install --upgrade --force-reinstall setuptools
python3.14 -m pip install --upgrade six
python3.14 -m pip install meson-python==0.13.1
python3.14 -m pip install patchelf==0.11.0
python3.14 -m pip install meson==1.2.1
python3.14 -m pip install oldest-supported-numpy==2022.8.16
python3.14 -m pip install ninja
python3.14 -m pip install versioneer[toml]
python3.14 -m pip install numpy==2.5.2

# Install pandas package
if ! (python3.14 -m pip install .); then
     echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
     echo "$PACKAGE_URL $PACKAGE_NAME"
     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | Python $PYTHON_VERSION | GitHub | Fail | Install_Fails"
     exit 1
fi

# Create pandas wheel - same approach as numpy
if ! python3.14 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"; then
        echo "============ Wheel Creation Failed for Python $PYTHON_VERSION (without isolation) ================="
        echo "Attempting to build with isolation..."

        if ! python3.14 -m build --wheel --outdir="$CURRENT_DIR/"; then
            echo "============ Wheel Creation Failed for Python $PYTHON_VERSION ================="
        fi
fi

cd ..

# Test pandas package
if ! (python3.14 -c "import pandas; print(pandas.__version__)"); then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | Python $PYTHON_VERSION | GitHub | Fail | Install_Success_But_Test_Fails"
    exit 2
else
   echo "------------------$PACKAGE_NAME:Install_and_test_success---------------------------"
   echo "$PACKAGE_URL $PACKAGE_NAME"
   echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | Python $PYTHON_VERSION | GitHub | Pass | Install_and_Test_Success"
   exit 0
fi