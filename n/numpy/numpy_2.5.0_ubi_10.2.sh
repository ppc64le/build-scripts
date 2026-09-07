#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numpy
# Version       : v2.5.0
# Source repo   : https://github.com/numpy/numpy
# Tested on     : UBI:10.2
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=numpy
PACKAGE_VERSION=${1:-v2.5.0}
PACKAGE_URL=https://github.com/numpy/numpy.git
PACKAGE_DIR=numpy
CURRENT_DIR="${PWD}"

yum install -y wget python3.14 python3.14-devel python3.14-pip git gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ gcc-toolset-15-gcc-gfortran make pkgconf-pkg-config

# Activate GCC Toolset 15
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

# GCC Toolset 15 compilers
export CC="$(command -v gcc)"
export CXX="$(command -v g++)"
export FC="$(command -v gfortran)"
export AR="$(command -v ar)"
export LD="$(command -v ld)"
export NM="$(command -v nm)"
export OBJCOPY="$(command -v objcopy)"
export OBJDUMP="$(command -v objdump)"
export RANLIB="$(command -v ranlib)"
export STRIP="$(command -v strip)"
export READELF="$(command -v readelf)"

python3.14 -m pip install --upgrade pip
python3.14 -m pip install tox Cython pytest hypothesis wheel meson ninja build meson-python patchelf

# OpenBLAS
OPENBLAS_VERSION=v0.3.33
OPENBLAS_URL=https://github.com/OpenMathLib/OpenBLAS
OPENBLAS_PREFIX=/opt/openblas

git clone "${OPENBLAS_URL}"
cd OpenBLAS
git checkout "${OPENBLAS_VERSION}"
git submodule update --init

export USE_OPENMP=1
export USE_THREAD=1
export NUM_THREADS=8
export TARGET=POWER9
export DYNAMIC_ARCH=1
export INTERFACE64=0
export BUILD_BFLOAT16=1
export NO_AFFINITY=1

export CF="${CFLAGS:-} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS

export LDFLAGS="$(echo "${LDFLAGS:-}" | sed 's/-Wl,--gc-sections//g')"

if [ -n "${FFLAGS:-}" ]; then
    export FFLAGS="${FFLAGS/-fopenmp/ }"
    export FFLAGS="${FFLAGS} -frecursive"
    export LAPACK_FFLAGS="${FFLAGS}"
fi

make -j"${MAX_JOBS:-$(nproc)}" \
    TARGET="${TARGET}" \
    BUILD_BFLOAT16="${BUILD_BFLOAT16}" \
    BINARY=64 \
    USE_OPENMP="${USE_OPENMP}" \
    USE_THREAD="${USE_THREAD}" \
    NUM_THREADS="${NUM_THREADS}" \
    DYNAMIC_ARCH="${DYNAMIC_ARCH}" \
    INTERFACE64="${INTERFACE64}" \
    NO_AFFINITY="${NO_AFFINITY}" \
    CFLAGS="${CF}" \
    FFLAGS="${FFLAGS:-}"

make install PREFIX="${OPENBLAS_PREFIX}"

export LD_LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${OPENBLAS_PREFIX}/lib64:${LD_LIBRARY_PATH:-}"
export LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${OPENBLAS_PREFIX}/lib64:${LIBRARY_PATH:-}"
export CPATH="${OPENBLAS_PREFIX}/include:${CPATH:-}"
export PKG_CONFIG_PATH="${OPENBLAS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

pkg-config --modversion openblas

cd "${CURRENT_DIR}"

# NumPy
git clone "${PACKAGE_URL}"
cd "${PACKAGE_DIR}"
git checkout "${PACKAGE_VERSION}"
git submodule update --init

UNAME_M=$(uname -m)
case "$UNAME_M" in
    ppc64*)
        export CXXFLAGS="$(echo "${CXXFLAGS:-}" | sed -e 's/ -fno-plt//')"
        export CFLAGS="$(echo "${CFLAGS:-}" | sed -e 's/ -fno-plt//')"
        ;;
esac

if ! python3.14 -m pip install . --no-build-isolation; then
    echo "------------------${PACKAGE_NAME}:Install_fails-------------------------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_Fails"
    exit 1
fi

if ! python3.14 -m build --wheel --no-isolation --outdir="${CURRENT_DIR}/"; then
    echo "============ Wheel Creation Failed for Python 3.14 (without isolation) ============"

    if ! python3.14 -m build --wheel --outdir="${CURRENT_DIR}/"; then
        echo "============ Wheel Creation Failed for Python 3.14 ==============================="
        exit 1
    fi
fi

export CFLAGS="-DCYTHON_PEP489_MULTI_PHASE_INIT=0"

if ! tox -e py3; then
    echo "--------------------${PACKAGE_NAME}:Install_success_but_test_fails---------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Install_success_but_test_Fails"
    exit 2
else
    echo "------------------${PACKAGE_NAME}:Install_&_test_both_success-------------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Pass | Both_Install_and_Test_Success"
    exit 0
fi