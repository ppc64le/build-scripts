#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : torch-c-dlpack-ext
# Version       : 0.1.5
# Source repo   : https://github.com/apache/tvm-ffi (addons/torch_c_dlpack_ext/)
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

PACKAGE_NAME=torch-c-dlpack-ext
PACKAGE_VERSION=${1:-v0.1.12}
PACKAGE_URL=https://github.com/apache/tvm-ffi
PACKAGE_DIR=tvm-ffi
CURRENT_DIR=$(pwd)

# Install dependencies
yum install -y git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    python3.12 python3.12-devel python3.12-pip make

# Configure GCC Toolset 15
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
pip install --upgrade pip setuptools wheel build

# apache-tvm-ffi must be installed before building torch-c-dlpack-ext because
# the custom build_backend.py imports tvm_ffi.libinfo.find_dlpack_include_path
# at wheel build time to locate the dlpack headers.
pip install apache-tvm-ffi==${PACKAGE_VERSION#v}

# Install PyTorch (CPU build sufficient -- the build backend checks
# torch.cuda.is_available() and falls back to a CPU-only .so when no GPU is
# present on the build host; the ROCm .so is JIT-compiled at first runtime
# import on the actual GPU host)
pip install torch \
    --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/

# Clone repository (reuses existing clone if already present from the
# apache-tvm-ffi build script running on the same host)
cd $CURRENT_DIR
rm -rf $PACKAGE_DIR
git clone $PACKAGE_URL $PACKAGE_DIR
cd $PACKAGE_DIR
git checkout $PACKAGE_VERSION

# Build wheel from the addon subdirectory.
# The custom build_backend.py (setuptools>=61.0 only) compiles
# libtorch_c_dlpack_addon_torch<major><minor>-cpu.so via the host CXX compiler
# and bundles it into the wheel package directory before calling
# setuptools.build_meta.build_wheel.
cd addons/torch_c_dlpack_ext
python3.12 -m build --wheel --no-isolation
cp dist/*.whl $CURRENT_DIR/

# Install package
if ! pip install dist/torch_c_dlpack_ext-*.whl ; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests
cd $CURRENT_DIR/$PACKAGE_DIR
if ! python3.12 -c "import torch_c_dlpack_ext; print('torch_c_dlpack_ext import test passed')" ; then
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
