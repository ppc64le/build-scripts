#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : tilelang
# Version       : 0.1.10
# Source repo   : https://github.com/tile-ai/tilelang
# Tested on     : UBI:10.2
# Language      : Python, C++
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Daniel Schenker <daniel.schenker@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=tilelang
PACKAGE_VERSION=${1:-0.1.10}
PACKAGE_URL=https://github.com/tile-ai/tilelang
PACKAGE_DIR=tilelang
CURRENT_DIR=$(pwd)

# Install dependencies
yum install -y python3.12 python3.12-devel python3.12-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    cmake ninja-build make

# Configure GCC Toolset 15
# Enable before any pip install so subprocesses spawned by pip inherit the
# toolset gcc/ar/etc on PATH (e.g. when building numpy/cython C extensions).
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

echo "Using gcc: $(gcc --version | head -1)"

# Install Python build tools
pip3.12 install --upgrade pip setuptools wheel build

# Install z3-solver from IBM wheels index (required by tilelang)
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
pip3.12 install --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url "${IBM_WHEELS}" --prefer-binary numpy tqdm cython patchelf "scikit-build-core[pyproject]" cmake ninja

# Clone repository
cd $CURRENT_DIR
git clone --recursive $PACKAGE_URL $PACKAGE_DIR
cd $PACKAGE_DIR
git checkout "v${PACKAGE_VERSION}"
git submodule sync --recursive
git submodule update --init --recursive

# Build TileLang wheel
# USE_ROCM/USE_CUDA must be exported as environment variables AND passed via
# CMAKE_ARGS. version_provider.py reads os.environ directly (not CMAKE_ARGS)
# to decide the wheel name suffix; without the exports it falls through to the
# cuda branch and labels the wheel +cuda instead of +rocm.
export USE_ROCM=ON
export USE_CUDA=OFF
export CMAKE_ARGS="-DUSE_ROCM=ON -DUSE_CUDA=OFF"

# Install package
if ! python3.12 -m build --wheel --no-isolation ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Copy wheel to CURRENT_DIR
cp dist/*.whl $CURRENT_DIR/

# Run tests
if ! python3.12 -c "import tilelang; print('tilelang import OK')" ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
else
    echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
    exit 0
fi
