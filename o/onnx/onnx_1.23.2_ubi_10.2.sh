#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnx
# Version          : 1.23.2
# Source repo      : https://github.com/onnx/onnx
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Vinit Janbandhu <Vinit.Janbandhu@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=onnx
PACKAGE_VERSION=${1:-v1.23.2}
PACKAGE_URL=https://github.com/onnx/onnx
PACKAGE_DIR=onnx
CURRENT_DIR=$(pwd)
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
IBM_WHEELS_HOST="wheels.developerfirst.ibm.com"

# System dependencies (curl is already provided by curl-minimal)
yum install -y python3.14 python3.14-devel python3.14-pip git cmake make \
    gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    libatomic zlib-devel tar which

# Enable the GCC toolset
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:${LD_LIBRARY_PATH:-}"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

# Python build tools (ninja from pip; pyproject pins protobuf==6.31.1 for the build)
python3.14 -m pip install --upgrade pip setuptools wheel build
python3.14 -m pip install "scikit-build-core>=0.11" ninja nanobind "protobuf==6.31.1"

# Runtime and test dependencies (numpy from IBM wheel index, version picked per Python)
python3.14 -m pip install --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" --prefer-binary numpy
python3.14 -m pip install "typing_extensions>=4.7.1" "ml_dtypes>=0.5.4" \
    pytest pytest-xdist parameterized Pillow packaging

# Clone source
cd "${CURRENT_DIR}"
if [[ ! -d "${PACKAGE_DIR}" ]]; then
    git clone "${PACKAGE_URL}"
fi
cd "${PACKAGE_DIR}"
git checkout "${PACKAGE_VERSION}"

# CMake fetches protobuf and abseil itself
export ONNX_BUILD_CUSTOM_PROTOBUF=ON
export CMAKE_GENERATOR=Ninja
export CMAKE_BUILD_PARALLEL_LEVEL=$(nproc)

# Build wheel into the current dir
if ! python3.14 -m build --wheel --no-isolation --outdir="${CURRENT_DIR}"; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Install wheel
if ! python3.14 -m pip install --no-deps --force-reinstall "${CURRENT_DIR}"/onnx-*.whl; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Plain pytest does not add the source dir to sys.path, so the installed wheel is tested
if ! pytest tests/python -p no:cacheprovider \
    --ignore=tests/python/reference_evaluator_test.py \
    --ignore=tests/python/backend_reference_test.py; then
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
