#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : h5py
# Version       : 3.16.0
# Source repo   : https://github.com/h5py/h5py.git
# Tested on     : UBI:10.2
# Language      : Python
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=h5py
PACKAGE_VERSION=${1:-3.16.0}
PACKAGE_URL=https://github.com/h5py/h5py.git
OPENBLAS_VERSION=v0.3.33
OPENBLAS_URL=https://github.com/OpenMathLib/OpenBLAS
HDF5_VERSION=hdf5-1_12_1
HDF5_URL=https://github.com/HDFGroup/hdf5

CURRENT_DIR="${PWD}"
INSTALL_ROOT="/install-deps"
MAX_JOBS=${MAX_JOBS:-8}

OPENBLAS_PREFIX="${INSTALL_ROOT}/openblas"
HDF5_PREFIX="${INSTALL_ROOT}/hdf5"

GCC_HOME=/opt/rh/gcc-toolset-15/root/usr

yum install -y wget python3.14 python3.14-pip python3.14-devel gcc-toolset-15 gcc-toolset-15-binutils gcc-toolset-15-binutils-devel gcc-toolset-15-gcc-c++ git make cmake binutils pkgconfig libffi-devel openssl-devel sqlite-devel zlib zlib-devel zip rsync

export PATH="${GCC_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${GCC_HOME}/lib64:${LD_LIBRARY_PATH:-}"
export GCC_HOME
export CC="${GCC_HOME}/bin/gcc"
export CXX="${GCC_HOME}/bin/g++"

gcc --version

python3.14 -m pip install --upgrade pip

mkdir -p "${OPENBLAS_PREFIX}" "${HDF5_PREFIX}"

python3.14 -m pip install cython setuptools==77.0.1 wheel ninja build pytest pytest-mpi tox pkgconfig

cd "${CURRENT_DIR}"

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

make -j"${MAX_JOBS}" TARGET="${TARGET}" BUILD_BFLOAT16="${BUILD_BFLOAT16}" BINARY=64 USE_OPENMP="${USE_OPENMP}" USE_THREAD="${USE_THREAD}" NUM_THREADS="${NUM_THREADS}" DYNAMIC_ARCH="${DYNAMIC_ARCH}" INTERFACE64="${INTERFACE64}" NO_AFFINITY="${NO_AFFINITY}" CFLAGS="${CF}" FFLAGS="${FFLAGS:-}"

make install PREFIX="${OPENBLAS_PREFIX}"

export LD_LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${OPENBLAS_PREFIX}/lib64:${LD_LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="${OPENBLAS_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

pkg-config --modversion openblas

echo "-----------------------------------------------------Installed OpenBLAS-----------------------------------------------------"

python3.14 -m pip install numpy==2.5.0 setuptools==77.0.1

python3.14 -c "import numpy; print(numpy.__version__)"

cd "${CURRENT_DIR}"

git clone "${HDF5_URL}"
cd hdf5
git checkout "${HDF5_VERSION}"
git submodule update --init

./configure --prefix="${HDF5_PREFIX}" --enable-cxx --enable-fortran --with-pthread=yes --enable-threadsafe --enable-build-mode=production --enable-unsupported --enable-using-memchecker --enable-clear-file-buffers --with-ssl

make -j"${MAX_JOBS}"
make install

export LD_LIBRARY_PATH="${HDF5_PREFIX}/lib:${LD_LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="${HDF5_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

echo "-----------------------------------------------------Installed HDF5-----------------------------------------------------"

cd "${CURRENT_DIR}"

wget -O pyproject.toml https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/h/hdf5/pyproject.toml

sed -i "s/{PACKAGE_VERSION}/${HDF5_VERSION}/g" pyproject.toml

sed -i 's/version = "hdf5[._-]\([0-9]*\)[._-]\([0-9]*\)[._-]\([0-9]*\)\([._-]*[0-9]*\)"/version = "\1.\2.\3\4"/' pyproject.toml

mkdir -p local
python3.14 -m pip install .

cd "${CURRENT_DIR}"

git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

python3.14 -m pip install pkgconfig pytest-mpi setuptools==77.0.1 wheel pytest tox build

HDF5_DIR="${HDF5_PREFIX}" python3.14 -m pip install .

cd "${CURRENT_DIR}"

python3.14 -c "import h5py; print(h5py.__version__)"

echo "-----------------------------------------------------Installed h5py-----------------------------------------------------"

cd "${CURRENT_DIR}/${PACKAGE_NAME}"

if ! HDF5_DIR="${HDF5_PREFIX}" python3.14 -m build --wheel --no-isolation --outdir="${CURRENT_DIR}"; then
    echo "------------------${PACKAGE_NAME}:Wheel_build_fails-------------------------------------"
    echo "${PACKAGE_URL} ${PACKAGE_NAME}"
    echo "${PACKAGE_NAME} | ${PACKAGE_URL} | ${PACKAGE_VERSION} | GitHub | Fail | Wheel_build_fails"
    exit 1
fi

echo "Generated wheel:"
find "${CURRENT_DIR}" -maxdepth 1 -type f -name "${PACKAGE_NAME}-*.whl" -print

echo "Executing the Testcases"

cd "${CURRENT_DIR}"

if ! python3.14 -m pytest --pyargs h5py -k "not test_append_permissions and not test_complex256 and not test_long_double and not test_custom_float_promotion"; then
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