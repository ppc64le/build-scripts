#!/bin/bash -e
# ----------------------------------------------------------------------------
#
# Package       : h5py
# Version       : 3.13.0
# Source repo   : https://github.com/h5py/h5py.git
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shubham Garud <Shubham.Garud@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
PACKAGE_NAME=h5py
PACKAGE_VERSION=${1:-3.13.0}
PACKAGE_URL=https://github.com/h5py/h5py.git
PACKAGE_DIR=h5py
SCRIPT_DIR=$(pwd)
CURRENT_DIR="${PWD}"

yum install -y python3.12 python3.12-pip python3.12-devel git wget  gcc-toolset-13
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
yum install -y make cmake zlib zlib-devel
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
gcc --version
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
LOCAL_DIR=local
CPU_COUNT=`python3.12 -c 'import multiprocessing ; print (multiprocessing.cpu_count())'`

PYTHON_VERSION=python$(python3.12 --version 2>&1 | cut -d ' ' -f 2 | cut -d '.' -f 1,2)
export SITE_PACKAGE_PATH="/usr/local/lib/${PYTHON_VERSION}/site-packages"

#build hdf5
git clone https://github.com/HDFGroup/hdf5
cd hdf5/
git checkout hdf5-1_12_1
git submodule update --init

mkdir -p $LOCAL_DIR/hdf5
export PREFIX=$(pwd)/$LOCAL_DIR/hdf5
./configure --prefix=${PREFIX} --enable-cxx --enable-fortran -with-pthread=yes --enable-threadsafe --enable-build-mode=production --enable-unsupported  --enable-using-memchecker --enable-clear-file-buffers  --with-ssl
make -j "${CPU_COUNT}"
make install PREFIX="${PREFIX}"
touch $LOCAL_DIR/hdf5/__init__.py

wget https://raw.githubusercontent.com/ppc64le/build-scripts/1423375e65a9eb5ab3fb37fe8b8f3e18acafbc97/h/hdf5/pyproject.toml
sed -i s/{PACKAGE_VERSION}/hdf5-1_12_1/g pyproject.toml
sed -i 's/version = "hdf5[._-]\([0-9]*\)[._-]\([0-9]*\)[._-]\([0-9]*\)\([._-]*[0-9]*\)"/version = "\1.\2.\3\4"/' pyproject.toml
python3.12 -m pip install .

yum install -y git make cmake wget python3.12 python3.12-devel python3.12-pip pkgconfig atlas
yum install gcc-toolset-13 -y
yum install -y make libtool cmake git wget xz zlib-devel openssl-devel bzip2-devel libffi-devel libevent-devel python3.12 python3.12-devel python3.12-pip patch ninja-build gcc-toolset-13  pkg-config
dnf install -y gcc-toolset-13-libatomic-devel

#build openblas
gcc --version
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
export LD_LIBRARY_PATH="$OpenBLASInstallPATH/lib":${LD_LIBRARY_PATH}
export PKG_CONFIG_PATH="$OpenBLASInstallPATH/lib/pkgconfig:${PKG_CONFIG_PATH}"
export LD_LIBRARY_PATH=${PREFIX}/lib:$LD_LIBRARY_PATH
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig:$PKG_CONFIG_PATH
pkg-config --modversion openblas
echo "--------------------openblas installed-------------------------------"
echo $SCRIPT_DIR
cd ..

python3.12 -m pip install setuptools==77.0.1

#build h5py
cd $SCRIPT_DIR
git clone $PACKAGE_URL
cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

echo "Dependencies installation"

python3.12 -m pip install Cython==0.29.36
python3.12 -m pip install numpy==2.0.2
python3.12 -m pip install pkgconfig pytest-mpi setuptools
python3.12 -m pip install wheel pytest pytest-mpi tox build

echo "export statmenents"
export LD_LIBRARY_PATH=${PREFIX}/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/hdf5/local/hdf5/include:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/hdf5/local/hdf5/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/lib/python3.12/site-packages/hdf5/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/hdf5/src/.libs/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/hdf5/build/lib/hdf5/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/hdf5/src/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/hdf5/local/hdf5/include/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/hdf5/build/lib/hdf5/include/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/lib/python3.12/site-packages/hdf5/include/:$LD_LIBRARY
export LD_LIBRARY_PATH=/usr/local/hdf5/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/hdf5/lib/:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/local/hdf5/include:$LD_LIBRARY_PATH
export HDF5_DIR=/usr/local/hdf5

echo "Installation" 

if ! (HDF5_DIR=/hdf5/local/hdf5 python3.12  -m pip install .);then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

#building wheel
if ! (HDF5_DIR=/hdf5/local/hdf5 python3.12 -m build --wheel --no-isolation --outdir="$CURRENT_DIR/");then
    echo "------------------$PACKAGE_NAME:Wheel_build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Wheel_build_fails"
    exit 1
fi

echo "Executing the Testcases"
cd ..

if ! (python -m pytest --pyargs h5py -k "not test_append_permissions"); then
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
