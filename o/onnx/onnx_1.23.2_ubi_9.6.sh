#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnx
# Version          : 1.23.2
# Source repo      : https://github.com/onnx/onnx
# Tested on        : UBI:9.6
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
CURRENT_DIR=$(pwd)
PYTHON=python3.12
GCC_TOOLSET=gcc-toolset-13
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
IBM_WHEELS_HOST="wheels.developerfirst.ibm.com"

# System dependencies
yum install -y ${PYTHON} ${PYTHON}-devel ${PYTHON}-pip git cmake make \
    ${GCC_TOOLSET} ${GCC_TOOLSET}-gcc ${GCC_TOOLSET}-gcc-c++ \
    libatomic zlib-devel libjpeg-turbo-devel curl tar which

# Enable the GCC toolset
if [[ -f /opt/rh/${GCC_TOOLSET}/enable ]]; then
    source /opt/rh/${GCC_TOOLSET}/enable
elif [[ -d /opt/rh/${GCC_TOOLSET}/root/usr/bin ]]; then
    export PATH="/opt/rh/${GCC_TOOLSET}/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/${GCC_TOOLSET}/root/usr/lib64:${LD_LIBRARY_PATH:-}"
else
    echo "ERROR: ${GCC_TOOLSET} not found"
    exit 1
fi

# Python build tools (cmake needs >=3.26, ninja from pip)
${PYTHON} -m pip install --upgrade pip setuptools wheel build
${PYTHON} -m pip install "scikit-build-core>=0.11" ninja nanobind

# Runtime and test dependencies (numpy from IBM wheel index)
${PYTHON} -m pip install --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" --prefer-binary "numpy==2.5.0"
${PYTHON} -m pip install "protobuf==6.33.6" "typing_extensions>=4.7.1" "ml_dtypes>=0.5.4" \
    pytest pytest-xdist parameterized Pillow packaging

# Clone source
cd "${CURRENT_DIR}"
if [[ ! -d "${PACKAGE_NAME}" ]]; then
    git clone "${PACKAGE_URL}"
fi
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"

# CMake fetches protobuf and abseil itself
export ONNX_BUILD_CUSTOM_PROTOBUF=ON
export CMAKE_GENERATOR=Ninja
export CMAKE_BUILD_PARALLEL_LEVEL=$(nproc)

# Build wheel
if ! ${PYTHON} -m build --wheel --no-isolation --outdir="${CURRENT_DIR}/wheels"; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

# Install wheel
if ! ${PYTHON} -m pip install --no-deps --force-reinstall "${CURRENT_DIR}"/wheels/onnx-*.whl; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Run tests with the pytest entry point so the installed wheel is used, not the source tree
cd "${CURRENT_DIR}/${PACKAGE_NAME}"
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
