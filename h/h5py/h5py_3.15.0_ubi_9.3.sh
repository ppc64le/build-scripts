#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : h5py
# Version       : 3.15.0
# Source repo   : https://github.com/h5py/h5py.git
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivansh sharma <Shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=h5py
PACKAGE_VERSION=${1:-3.15.0}
PACKAGE_URL=https://github.com/h5py/h5py.git
PACKAGE_DIR=h5py
CURRENT_DIR="${PWD}"

# install core dependencies
yum install -y wget python3.12 python3.12-pip python3.12-devel  gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++ git make cmake binutils pkgconfig 

yum install -y libffi-devel openssl-devel sqlite-devel zip rsync

export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
gcc --version

export GCC_HOME=/opt/rh/gcc-toolset-13/root/usr
export CC=$GCC_HOME/bin/gcc
export CXX=$GCC_HOME/bin/g++
LOCAL_DIR=local

OS_NAME=$(cat /etc/os-release | grep ^PRETTY_NAME | cut -d= -f2)

python3.12 -m pip install --upgrade pip

INSTALL_ROOT="/install-deps"
mkdir -p $INSTALL_ROOT


for package in openblas hdf5 ; do
    mkdir -p ${INSTALL_ROOT}/${package}
    export "${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
    echo "Exported ${package^^}_PREFIX=${INSTALL_ROOT}/${package}"
done

python3.12 -m pip install cython setuptools wheel ninja build pytest pytest-mpi

#installing openblas
cd $CURRENT_DIR
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init
# Set build options
declare -a build_opts
# Fix ctest not automatically discovering tests
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")
export CF="${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS
export USE_OPENMP=1
build_opts+=(USE_OPENMP=${USE_OPENMP})
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
make ${build_opts[@]} CFLAGS="${CF}" FFLAGS="${FFLAGS}" prefix=${OPENBLAS_PREFIX}
# Install OpenBLAS
CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${OPENBLAS_PREFIX}" ${build_opts[@]}
export LD_LIBRARY_PATH=${OPENBLAS_PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${OPENBLAS_PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
pkg-config --modversion openblas
echo "-----------------------------------------------------Installed openblas-----------------------------------------------------"
python3.12 -m pip install numpy==2.0.2 setuptools==77.0.1


#Build hdf5 from source
cd $CURRENT_DIR
git clone https://github.com/HDFGroup/hdf5
cd hdf5/
git checkout hdf5-1_12_1
git submodule update --init

mkdir -p $LOCAL_DIR/$PACKAGE_NAME
yum install -y zlib zlib-devel

./configure --prefix=$HDF5_PREFIX --enable-cxx --enable-fortran  --with-pthread=yes --enable-threadsafe  --enable-build-mode=production --enable-unsupported  --enable-using-memchecker  --enable-clear-file-buffers --with-ssl
make 
make install PREFIX="${HDF5_PREFIX}"

export LD_LIBRARY_PATH=${HDF5_PREFIX}/lib:$LD_LIBRARY_PATH
# touch $LOCAL_DIR/hdf5/__init__.py

echo "-----------------------------------------------------Installed hdf5-----------------------------------------------------"
wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/h/hdf5/pyproject.toml
sed -i s/{PACKAGE_VERSION}/hdf5-1_12_1/g pyproject.toml
sed -i 's/version = "hdf5[._-]\([0-9]*\)[._-]\([0-9]*\)[._-]\([0-9]*\)\([._-]*[0-9]*\)"/version = "\1.\2.\3\4"/' pyproject.toml
python3.12 -m pip install .


#Build h5py from source
cd $CURRENT_DIR
git clone https://github.com/h5py/h5py.git
cd h5py/
git checkout $PACKAGE_VERSION

python3.12 -m pip install numpy==2.0.2
python3.12 -m pip install pkgconfig pytest-mpi setuptools==77.0.1
python3.12 -m pip install wheel pytest pytest-mpi tox build

HDF5_DIR=/install-deps/hdf5 python3.12 -m pip install .
cd $CURRENT_DIR
python3.12 -c "import h5py; print(h5py.__version__)"
echo "-----------------------------------------------------Installed h5py-----------------------------------------------------"
cd h5py/
#building wheel
if ! (HDF5_DIR=/install-deps/hdf5 python3.12 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/");then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Wheel_build_fails"
    exit 1
fi

echo "Executing the Testcases"
cd ..

if ! (python3.12 -m pytest --pyargs h5py -k "not test_append_permissions"); then
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