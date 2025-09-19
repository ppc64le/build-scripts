#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : xgboost
# Version       : 3.0.1
# Source repo   :  https://github.com/dmlc/xgboost
# Tested on     : UBI:9.3
# Language      : Python
# Travis-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Shivansh Sharma <shivansh.s1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on the given
# platform using the mentioned version of the package.
# It may not work as expected with newer versions of the
# package and/or distribution. In such a case, please
# contact the "Maintainer" of this script.
#
# -----------------------------------------------------------------------------
# Exit immediately if a command exits with a non-zero status
set -e
# Variables
PACKAGE_NAME=xgboost
PACKAGE_VERSION=${1:-v3.0.1}
PACKAGE_URL=https://github.com/dmlc/xgboost
PACKAGE_DIR=xgboost/python-package
OUTPUT_FOLDER="$(pwd)/output"
SCRIPT_DIR=$(pwd)

echo "PACKAGE_NAME: $PACKAGE_NAME"
echo "PACKAGE_VERSION: $PACKAGE_VERSION"
echo "PACKAGE_URL: $PACKAGE_URL"
echo "OUTPUT_FOLDER: $OUTPUT_FOLDER"

# Install dependencies
echo "Installing dependencies..."
yum install -y git wget gcc-toolset-13 gcc-toolset-13-gcc-gfortran python3.12 python3.12-devel python3.12-pip openssl-devel cmake
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH


#clone and install openblas from source
git clone https://github.com/OpenMathLib/OpenBLAS
cd OpenBLAS
git checkout v0.3.29
git submodule update --init

PREFIX=local/openblas
OPENBLAS_SOURCE=$(pwd)

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

echo " ------------------------------------------ Openblas Successfully Installed ------------------------------------------ "

cd ${SCRIPT_DIR}

pip3.12 install numpy==2.0.2 packaging pathspec pluggy scipy==1.15.2 trove-classifiers pytest wheel build hatchling joblib threadpoolctl

# Clone the repository
echo "Cloning the repository..."
mkdir -p output
git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION
git submodule update --init
export SRC_DIR=$(pwd)
echo "SRC_DIR: $SRC_DIR"
 
sed -i '/^from hatchling\.builders\.hooks\.plugin\.interface import BuildHookInterface/a import sysconfig' python-package/hatch_build.py
# set platform tag to linux_ppc64le instead of the default manylinux_2_34_ppc64le tag.
sed -i 's/next(platform_tags())/sysconfig.get_platform().replace("-", "_").replace(".", "_")/g' python-package/hatch_build.py

# Build xgboost cpp artifacts
echo "Building xgboost cpp artifacts..."
cd ${SRC_DIR}
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX=${OUTPUT_FOLDER} ..
make -j$(nproc)

LIBDIR=${OUTPUT_FOLDER}/lib
INCDIR=${OUTPUT_FOLDER}/include
BINDIR=${OUTPUT_FOLDER}/bin
SODIR=${LIBDIR}
XGBOOSTDSO=libxgboost.so

mkdir -p ${LIBDIR} ${INCDIR}/xgboost ${BINDIR} || true
cp ${SRC_DIR}/lib/${XGBOOSTDSO} ${SODIR}
cp -Rf ${SRC_DIR}/include/xgboost ${INCDIR}/
# Copy rabit headers only if version < 3.0.0
version_less_than_3=$(printf '%s\n3.0.0' "${PACKAGE_VERSION#v}" | sort -V | head -n1)
if [[ "$version_less_than_3" != "3.0.0" ]]; then
    echo "Copying rabit headers (only for xgboost < 3.0.0)..."
    cp -Rf ${SRC_DIR}/rabit/include/rabit ${INCDIR}/xgboost/
else
    echo "Skipping rabit copy (xgboost >= 3.0.0)..."
fi
cp -f ${SRC_DIR}/src/c_api/*.h ${INCDIR}/xgboost/
cd ../../

# Build xgboost python artifacts and wheel
echo "Building xgboost Python artifacts and wheel..."
cd "$(pwd)/$PACKAGE_DIR"
echo "Current directory: $(pwd)"

# Remove the nvidia-nccl-cu12 dependency in pyproject.toml (not required for Power)
echo "Removing nvidia-nccl-cu12 dependency from pyproject.toml..."
sed -i '/nvidia-nccl-cu12/d' pyproject.toml

# Only add the section if it doesn't exist
# This line checks whether "tool.hatch.build.targets.wheel" is present in pyproject.toml or not. If not then add this "tool.hatch.build.targets.wheel" and packages=["xgboost"] to pyproject.toml
grep -q '^\[tool.hatch.build.targets.wheel\]' pyproject.toml || echo -e '\n[tool.hatch.build.targets.wheel]\npackages = ["xgboost/"]' >> pyproject.toml
sed -i 's/^name[[:space:]]*=[[:space:]]*"xgboost"$/name = "xgboost-cpu"/' pyproject.toml #Changing the name xgboost as xgboost-cpu

# Ensure no build isolation and deps are used
if ! (python3.12 -m build); then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi
echo "Build and installation completed successfully."

echo "Import check"
python3.12 -c "import xgboost;"

if [ $? -eq 0 ]; then
    echo " ------------------------ $PACKAGE_NAME:Both_Install_and_Test_Success ------------------------ "
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Pass |  Both_Install_and_Test_Success"
    exit 0
else
    echo " ------------------------ $PACKAGE_NAME:Install_success_but_test_Fails ------------------------ "
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Fail |  Install_success_but_test_Fails"
    exit 2
fi

echo "There are no test cases available. skipping the test cases"
