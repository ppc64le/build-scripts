#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : numba
# Version       : 0.62.0
# Source repo   : https://github.com/numba/numba
# Tested on     : UBI:9.3
# Language      : Python
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME=numba
PACKAGE_VERSION=${1:-0.62.0}
PACKAGE_URL=https://github.com/numba/numba
PACKAGE_DIR=numba
WORKING_DIR=$(pwd)
NUMERIC_VERSION=$(echo "$PACKAGE_VERSION" | grep -oP '^\d+(\.\d+){0,2}')

# Install necessary  dependencies

yum install -y git make wget python3.12 python3.12-devel python3.12-pip gcc-toolset-13 
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
export LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib/gcc/ppc64le-redhat-linux/13:$LIBRARY_PATH
export CPATH=/opt/rh/gcc-toolset-13/root/usr/include:$CPATH

yum install -y git make wget openssl-devel bzip2-devel libffi-devel zlib-devel cmake

echo "-------------------Installing llvmlite----------------------"

LLVMLITE_PACKAGE_NAME=llvmlite
# Determine the llvmlite version based on the Numba package version:
# - If Numba is 0.62.0 with dev/rc suffix → use llvmlite v0.44.0rc1
# - If Numba version >= 0.62.0 → use llvmlite v0.45.0dev0
# - If Numba version < 0.62.0 → use llvmlite v0.44.0rc1
if [[ "$NUMERIC_VERSION" ==  0.62.0 && "$PACKAGE_VERSION" =~ dev|rc ]]; then
    LLVMLITE_VERSION="v0.44.0rc1"
elif [[ "$(printf '%s\n' "$PACKAGE_VERSION" "0.62.0" | sort -V | head -n1)" == "0.62.0" ]]; then
    LLVMLITE_VERSION="v0.45.0dev0"
else
    LLVMLITE_VERSION="v0.44.0rc1"
fi
LLVMLITE_PACKAGE_URL="https://github.com/numba/llvmlite"
LLVM_PROJECT_GIT_URL="https://github.com/llvm/llvm-project.git"
LLVM_PROJECT_GIT_TAG="llvmorg-15.0.7"

git clone -b ${LLVM_PROJECT_GIT_TAG} ${LLVM_PROJECT_GIT_URL}
git clone -b ${LLVMLITE_VERSION} ${LLVMLITE_PACKAGE_URL}

python3.12 -m pip install ninja

# Build LLVM project
cd "$WORKING_DIR/llvm-project"
git apply "$WORKING_DIR/llvmlite/conda-recipes/llvm15-clear-gotoffsetmap.patch"
git apply "$WORKING_DIR/llvmlite/conda-recipes/llvm15-remove-use-of-clonefile.patch"
cp "$WORKING_DIR/llvmlite/conda-recipes/llvmdev/build.sh" .
chmod 777 "$WORKING_DIR/llvm-project/build.sh" && "$WORKING_DIR/llvm-project/build.sh"

# Set LLVM_CONFIG environment variable
export LLVM_CONFIG="/llvm-project/build/bin/llvm-config"

# Check for llvm-config path
LLVM_CONFIG_PATH=$(which llvm-config)

# If llvm-config is not found in the system path, use the local path from the build
if [ -z "$LLVM_CONFIG_PATH" ]; then
    echo "llvm-config not found in PATH, using local path."
    export LLVM_CONFIG="$WORKING_DIR/llvm-project/build/bin/llvm-config"
else
    echo "llvm-config found at: $LLVM_CONFIG_PATH"
    export LLVM_CONFIG="$LLVM_CONFIG_PATH"
fi

# Check if llvm-config.h exists in the build include directory
echo "Checking for llvm-config.h in: $WORKING_DIR/llvm-project/build/include/llvm/Config"
ls "$WORKING_DIR/llvm-project/build/include/llvm/Config/llvm-config.h" || { echo "llvm-config.h not found. Exiting."; exit 1; }

# Build llvmlite
cd "$WORKING_DIR/llvmlite"
export CXXFLAGS="-I$WORKING_DIR/llvm-project/build/include"
export LLVM_CONFIG="$WORKING_DIR/llvm-project/build/bin/llvm-config"

python3.12 -m pip install .
cd $WORKING_DIR

echo "-------------------successfully Installed llvmlite----------------------"


echo "---------------------------------Installing openblas from source----------------"
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init

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
echo "------------openblas installed--------------------"

python3.12 -m pip install numpy==2.0.2 setuptools

#clone repository
git clone $PACKAGE_URL
cd  $PACKAGE_DIR
git checkout $PACKAGE_VERSION



# echo "before CXXFLAGS............$CXXFLAGS........."
export CXXFLAGS=-I/usr/include
# echo "after CXXFLAGS............$CXXFLAGS........."

PYTHON_VERSION=$(python3.12 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
#sed -i '/#include "dynamic_annotations.h".*\/\*/d' /usr/include/python${PYTHON_VERSION}/internal/pycore_atomic.h
#sed -i '1i#include "dynamic_annotations.h"   /* _Py_ANNOTATE_MEMORY_ORDER */' /usr/include/python${PYTHON_VERSION}/internal/pycore_atomic.h


#install
if ! python3.12 -m pip install . ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# #test
# cd $WORKING_DIR
# if ! python3.12 -c "import numba; import numba.core.annotations; import numba.core.datamodel; import numba.core.rewrites; import numba.core.runtime; import numba.core.typing; import numba.core.unsafe; import numba.experimental.jitclass; import numba.np.ufunc; import numba.pycc; import numba.scripts; import numba.testing; import numba.tests; import numba.tests.npyufunc;"; then
#     echo "--------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
#     exit 2
# else
#     echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
#     echo "$PACKAGE_URL $PACKAGE_NAME"
#     echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
#     exit 0
# fi

# #Pytest taking more than 5 hours,so we are skipping pytest.
