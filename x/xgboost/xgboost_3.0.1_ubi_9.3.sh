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
yum install -y git wget gcc-toolset-13 gcc-toolset-13-gcc-gfortran python3.12 python3.12-devel python3.12-pip openssl-devel cmake openblas-devel
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
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

# Ensure no build isolation and deps are used
if ! (python3.12 -m build); then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail | Install_Fails"
    exit 1
fi
echo "Build and installation completed successfully."
echo "There are no test cases available. skipping the test cases"
