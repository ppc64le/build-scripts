#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numpy
# Version       : v2.2.5
# Source repo   : https://github.com/numpy/numpy
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sai Kiran Nukala <sai.kiran.nukala@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=numpy
PACKAGE_VERSION=${1:-v2.2.5}
PACKAGE_URL=https://github.com/numpy/numpy.git
PACKAGE_DIR=numpy
CURRENT_DIR="${PWD}"

yum install -y wget python3.12 python3.12-devel python3.12-pip git gcc-toolset-13-gcc gcc-toolset-13-gcc-c++ gcc-toolset-13-gcc-gfortran make
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
ln -sf /usr/bin/python3.12 /usr/bin/python3
python3 -m pip install --upgrade pip
python3 -m pip install tox Cython pytest hypothesis wheel meson ninja
export SITE_PACKAGE_PATH=/usr/local/lib/python3.12/site-packages

#clone and install openblas from source
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init

wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/openblas/pyproject.toml
sed -i "s/{PACKAGE_VERSION}/v0.3.29/g" pyproject.toml

PREFIX=local/openblas
# Set build options
declare -a build_opts
# Fix ctest not automatically discovering tests
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS
export USE_OPENMP=1
build_opts+=(USE_OPENMP=${USE_OPENMP})
export PREFIX=${PREFIX}
# Handle Fortran flags
if [ ! -z "$FFLAGS" ]; then
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi
export PLATFORM=$(uname -m)
build_opts+=(BINARY="64")
build_opts+=(DYNAMIC_ARCH=1)
build_opts+=(TARGET="POWER9")
BUILD_BFLOAT16=1
# Placeholder for future builds that may include ILP64 variants.
build_opts+=(INTERFACE64=0)
build_opts+=(SYMBOLSUFFIX="")
# Build LAPACK
build_opts+=(NO_LAPACK=0)
# Enable threading and set the number of threads
build_opts+=(USE_THREAD=1)
build_opts+=(NUM_THREADS=8)
# Disable CPU/memory affinity handling to avoid problems with NumPy and R
build_opts+=(NO_AFFINITY=1)
# Build OpenBLAS
make -j8 ${build_opts[@]} CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=${PREFIX}
# Install OpenBLAS
CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${PREFIX}" ${build_opts[@]}
OpenBLASInstallPATH=$(pwd)/$PREFIX
OpenBLASConfigFile=$(find . -name OpenBLASConfig.cmake)
OpenBLASPCFile=$(find . -name openblas.pc)
sed -i "/OpenBLAS_INCLUDE_DIRS/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" ${OpenBLASConfigFile}
sed -i "/OpenBLAS_LIBRARIES/c\SET(OpenBLAS_INCLUDE_DIRS ${OpenBLASInstallPATH}/include)" ${OpenBLASConfigFile}
sed -i "s|libdir=local/openblas/lib|libdir=${OpenBLASInstallPATH}/lib|" ${OpenBLASPCFile}
sed -i "s|includedir=local/openblas/include|includedir=${OpenBLASInstallPATH}/include|" ${OpenBLASPCFile}
export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib"
export PKG_CONFIG_PATH="$OpenBLASInstallPATH/lib/pkgconfig:${PKG_CONFIG_PATH}"
cd ..


#clone package
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION
git submodule update --init
EXTRA_OPTS=""
export GCC_HOME=/opt/rh/gcc-toolset-13/root/usr
echo $GCC_HOME

export PATH=$GCC_HOME/bin:$PATH
export CC=$GCC_HOME/bin/gcc
export CXX=$GCC_HOME/bin/g++
export GCC=$CC
export GXX=$CXX
export AR=${GCC_HOME}/bin/ar
export LD=${GCC_HOME}/bin/ld
export NM=${GCC_HOME}/bin/nm
export OBJCOPY=${GCC_HOME}/bin/objcopy
export OBJDUMP=${GCC_HOME}/bin/objdump
export RANLIB=${GCC_HOME}/bin/ranlib
export STRIP=${GCC_HOME}/bin/strip
export READELF=${GCC_HOME}/bin/readelf
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

if ! (python3 -m pip install . );then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

python3 -m pip install build meson-python patchelf
if ! python3 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/"; then
        echo "============ Wheel Creation Failed for Python $PYTHON_VERSION (without isolation) ================="
        echo "Attempting to build with isolation..."

        # Attempt to build the wheel without isolation
        if ! python3 -m build --wheel --outdir="$CURRENT_DIR/"; then
            echo "============ Wheel Creation Failed for Python $PYTHON_VERSION ================="
        fi
fi
cd ..

export CFLAGS="-DCYTHON_PEP489_MULTI_PHASE_INIT=0"

if ! (python3 -m pytest --pyargs numpy -m 'not slow'); then
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
