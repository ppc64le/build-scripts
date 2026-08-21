#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : pandas
# Version       : v2.3.3
# Source repo   : https://github.com/pandas-dev/pandas.git
# Tested on     : UBI 8.10
# Language      : Python, C, Cython
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Amit Kumar <amit.kumar282@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_NAME=pandas
PACKAGE_VERSION=${1:-v2.3.3}
PACKAGE_URL=https://github.com/pandas-dev/pandas.git
PACKAGE_DIR=pandas
CURRENT_DIR=${PWD}

# -----------------------------------------------------------------------------
# 1. Install system dependencies
# -----------------------------------------------------------------------------
yum install -y python3.12 python3.12-devel python3.12-pip git make cmake ninja-build binutils wget \
    gcc-toolset-13 gcc-toolset-13-binutils gcc-toolset-13-binutils-devel gcc-toolset-13-gcc-c++

# UBI 8.10 ships GCC 8.5. NumPy 2.x requires GCC >= 10.3.
# gcc-toolset-13 provides GCC 13 and is available in the standard UBI 8 repos.
source /opt/rh/gcc-toolset-13/enable
export PATH=/opt/rh/gcc-toolset-13/root/usr/bin:$PATH
export LD_LIBRARY_PATH=/opt/rh/gcc-toolset-13/root/usr/lib64:$LD_LIBRARY_PATH
echo "GCC version: $(gcc --version | head -1)"

# Remove existing repo
cd "$CURRENT_DIR"
[ -d "$PACKAGE_NAME" ] && rm -rf "$PACKAGE_NAME"

git clone $PACKAGE_URL
cd $PACKAGE_NAME/
git checkout $PACKAGE_VERSION

# Stamp the IBM local version label (+ppc64le1).
# PEP 440 local version: 2.3.3+ppc64le1
PLAIN_VERSION="${PACKAGE_VERSION#v}"
FULL_VERSION="${PLAIN_VERSION}+ppc64le1"

# pyproject.toml
sed -i "s/^version = \"${PLAIN_VERSION}\"/version = \"${FULL_VERSION}\"/" pyproject.toml
# meson.build
sed -i "s/version : '${PLAIN_VERSION}'/version : '${FULL_VERSION}'/" meson.build 2>/dev/null || true

# Setup virtual environment for python
python3.12 -m venv pandas-env
source pandas-env/bin/activate

python -m pip install --upgrade pip wheel setuptools
python -m pip install "numpy==2.0.2"
python -m pip install Cython pytest hypothesis build meson meson-python ninja "versioneer[toml]" patchelf

# -mcpu=power9 -mtune=power9 produces code that runs on Power9, Power10, Power11
export CFLAGS="-mcpu=power9 -mtune=power9 -O2"
export CXXFLAGS="-mcpu=power9 -mtune=power9 -O2"

# Build the package and create whl file
python -m build --wheel --no-isolation
if [ $? -eq 0 ]; then
    echo "------------------$PACKAGE_NAME::Build_Pass---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Pass | Build_Success"
else
    echo "------------------$PACKAGE_NAME::Build_Fail-------------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Fail | Build_Fail"
    exit 1
fi

# Run auditwheel to tag the wheel as manylinux_2_28_ppc64le.
# This is mandatory -- it verifies that no .so dependency requires glibc > 2.28
python -m pip install auditwheel
auditwheel repair --plat manylinux_2_28_ppc64le --wheel-dir wheelhouse dist/pandas-*.whl

DUAL_WHEEL=$(ls wheelhouse/pandas-*manylinux*.whl 2>/dev/null | head -1)
FINAL_WHEEL="wheelhouse/pandas-${FULL_VERSION}-cp312-cp312-manylinux_2_28_ppc64le.whl"
if [ "${DUAL_WHEEL}" != "${FINAL_WHEEL}" ] && [ -f "${DUAL_WHEEL}" ]; then
    mv "${DUAL_WHEEL}" "${FINAL_WHEEL}"
    echo "Renamed wheel: $(basename "${FINAL_WHEEL}")"
fi

python -m pip install --only-binary=:all: "${FINAL_WHEEL}"
if [ $? == 0 ]; then
     echo "------------------$PACKAGE_NAME::Install_Pass---------------------"
else
     echo "------------------$PACKAGE_NAME::Install_Fail---------------------"
     exit 1
fi

# Test the package
cd ..
if python -m pip show pandas && \
   python -c "import pandas; print('Version:', pandas.__version__); print('Location:', pandas.__file__)"; then

    echo "------------------$PACKAGE_NAME::Test_Pass---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Pass | Test_Success"

    deactivate
    exit 0
else
    echo "------------------$PACKAGE_NAME::Test_Fail---------------------"
    echo "$PACKAGE_NAME | $PACKAGE_URL | $PACKAGE_VERSION | Fail | Test_Fail"

    deactivate
    exit 2
fi
