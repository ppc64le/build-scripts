#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numpy
# Version       : v2.2.6
# Source repo   : https://github.com/numpy/numpy
# Tested on     : UBI:10.1
# Language      : Python
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
# ----------------------------------------------------------------------------
PACKAGE_NAME=numpy
PACKAGE_VERSION=${1:-v2.2.6}
PACKAGE_URL=https://github.com/numpy/numpy.git
PACKAGE_DIR=numpy
CURRENT_DIR="${PWD}"

yum install -y wget python3.12 python3.12-devel python3.12-pip git gcc gcc-c++ gcc-gfortran make pkgconf-pkg-config 
python3.12 -m pip install --upgrade pip
python3.12 -m pip install tox Cython pytest hypothesis wheel meson ninja build meson-python patchelf

#clone and install openblas from source
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.33
git submodule update --init

make -j$(nproc) TARGET=POWER9 BUILD_BFLOAT16=1 BINARY=64 USE_OPENMP=1 USE_THREAD=1 NUM_THREADS=120 DYNAMIC_ARCH=1 INTERFACE64=0
make install PREFIX=/usr/local

export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH
export LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=/usr/local/lib64:/usr/local/lib:$LIBRARY_PATH
export CPATH=/usr/local/include:$CPATH

cd ..

#clone package
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init
export CC=/usr/bin/gcc
export CXX=/usr/bin/g++
export FC=/usr/bin/gfortran
export AR=/usr/bin/ar
export LD=/usr/bin/ld
export NM=/usr/bin/nm
export OBJCOPY=/usr/bin/objcopy
export OBJDUMP=/usr/bin/objdump
export RANLIB=/usr/bin/ranlib
export STRIP=/usr/bin/strip
export READELF=/usr/bin/readelf
UNAME_M=$(uname -m)
case "$UNAME_M" in
    ppc64*)
        # Optimizations trigger compiler bug.
         export CXXFLAGS="$(echo ${CXXFLAGS} | sed -e 's/ -fno-plt//')"
         export CFLAGS="$(echo ${CFLAGS} | sed -e 's/ -fno-plt//')"
        ;;
    *)
        EXTRA_OPTS=""
        ;;
esac

if ! (python3.12 -m pip install . --no-build-isolation);then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

if ! python3.12 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"; then
        echo "============ Wheel Creation Failed for Python $PYTHON_VERSION (without isolation) ================="
        echo "Attempting to build with isolation..."

        # Attempt to build the wheel without isolation
        if ! python3.12 -m build --wheel --outdir="$CURRENT_DIR/"; then
            echo "============ Wheel Creation Failed for Python $PYTHON_VERSION ================="
        fi
fi

export CFLAGS="-DCYTHON_PEP489_MULTI_PHASE_INIT=0"

if ! (tox -e py3); then
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