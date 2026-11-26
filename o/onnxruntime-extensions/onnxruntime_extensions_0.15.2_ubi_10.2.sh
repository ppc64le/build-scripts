#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnxruntime-extensions
# Version          : v0.15.2
# Source repo      : https://github.com/microsoft/onnxruntime-extensions
# Tested on        : UBI:10.2
# Language         : Python
# Ci-Check         : True
# Script License   : Apache License, Version 2 or later
# Maintainer       : Siddesh Sangodkar <siddesh.sangodkar1@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# Note: onnxruntime-extensions 0.15.2 builds a CMake-backed C++ extension
#       that provides custom ONNX operators. No ppc64le wheel is available
#       on PyPI. The repo has no git tag for 0.15.x so we clone the default branch and
#       build via python setup.py bdist_wheel.
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=onnxruntime-extensions
PACKAGE_VERSION=${1:-v0.15.2}
PACKAGE_URL=https://github.com/microsoft/onnxruntime-extensions
PACKAGE_DIR=onnxruntime-extensions
CURRENT_DIR=$(pwd)
WHEEL_DIR="${CURRENT_DIR}/wheels"
mkdir -p "${WHEEL_DIR}"

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
IBM_WHEELS_HOST="wheels.developerfirst.ibm.com"

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    gcc-toolset-15-libatomic-devel \
    cmake ninja-build make \
    openssl-devel libffi-devel zlib-devel \
    libjpeg-turbo-devel libpng-devel \
    openblas-devel \
    which curl tar patch

# UBI 10 dropped SCL — guard block
if [[ -f /opt/rh/gcc-toolset-15/enable ]]; then
    source /opt/rh/gcc-toolset-15/enable
elif [[ -d /opt/rh/gcc-toolset-15/root/usr/bin ]]; then
    export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
    export LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:$LD_LIBRARY_PATH"
else
    echo "ERROR: gcc-toolset-15 not found"
    exit 1
fi

# ---------------------------------------------------------------------------
# Python build tools
# setuptools<80 required — newer versions break setup.py bdist_wheel builds
# ---------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip "setuptools<80" wheel ninja packaging pytest build installer

# Install build/runtime dependencies from IBM wheels index
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "numpy==2.5.0" \
    "onnx==1.21.0" \
    "onnxruntime==1.26.0" 
    
    

# Expose Python headers to the C/C++ compiler (required by setup.py CMake build)
PYTHON_INCLUDE=$(python3.14 -c "from sysconfig import get_paths; print(get_paths()['include'])")
export CPLUS_INCLUDE_PATH="${PYTHON_INCLUDE}:${CPLUS_INCLUDE_PATH}"
export C_INCLUDE_PATH="${PYTHON_INCLUDE}:${C_INCLUDE_PATH}"

# ---------------------------------------------------------------------------
# Clone default branch (0.15.2 is on main; no git tag exists for 0.15.x)
# ---------------------------------------------------------------------------
cd "${CURRENT_DIR}"
git clone "${PACKAGE_URL}" "${PACKAGE_DIR}"
cd "${PACKAGE_DIR}"

git submodule sync --recursive
git submodule update --init --recursive

# ---------------------------------------------------------------------------
# Patch: image_encoder.hpp hard-codes ZLIB_VERNUM == 0x12b0 (zlib 1.2.11).
# UBI 10.2 only ships zlib-ng-compat (ZLIB_VERNUM 0x131f). Remove the strict
# version check so the build proceeds with zlib-ng's compatible API.
# ---------------------------------------------------------------------------
sed -i 's|#if ZLIB_VERNUM != 0x12b0|#if 0 /* zlib-ng compat: skip version check */|' \
    operators/vision/image_encoder.hpp

# ---------------------------------------------------------------------------
# Build wheel via setup.py (invokes CMake internally)
# CMAKE_BUILD_PARALLEL_LEVEL — use all available cores
# ---------------------------------------------------------------------------
export CMAKE_BUILD_PARALLEL_LEVEL=$(nproc)

if ! python3.14 setup.py bdist_wheel --dist-dir="${WHEEL_DIR}"; then
    echo "------------------$PACKAGE_NAME:Install_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_Fails"
    exit 1
fi

# Copy wheel to CURRENT_DIR for create_wheel_wrapper.sh compatibility
cp "${WHEEL_DIR}"/*.whl "${CURRENT_DIR}/"

# Install the built wheel 
python3.14 -m installer "${WHEEL_DIR}"/*.whl

# Install requirements-dev.txt deps available on ppc64le. Required for running tests
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "scipy==1.18.0" \
    sentencepiece \
    requests \
    Pillow \
    safetensors \
    "torchvision==0.28.0" \
    "torch==2.13.0" \
    onnxscript

# Run from the test directory. Ignore tests that need transformers (heavy package
# requiring HF model downloads + HF_TOKEN).test_onnxprocess.py is ignored because
# onnxprocess submodule uses onnx.mapping (removed in onnx>=1.16) and crashes
# collection with onnx==1.21.0. test_custom_pythonop_pytorch — uses deprecated API incompatible with torch 2.13's new exporter
cd "${CURRENT_DIR}/${PACKAGE_DIR}/test"

if ! python3.14 -m pytest . --verbose \
    --ignore=test_onnxprocess.py \
    --ignore=test_processing.py \
    --ignore=test_autotokenizer.py \
    --ignore=test_bert_tokenizer.py \
    --ignore=test_bert_tokenizer_decoder.py \
    --ignore=test_bert_tokenizer_op.py \
    --ignore=test_bpe_tokenizer.py \
    --ignore=test_cliptok.py \
    --ignore=test_embedded_tokenizer.py \
    --ignore=test_fast_tokenizer.py \
    --ignore=test_gpt2tok.py \
    --ignore=test_robertatok.py \
    --ignore=test_sentencepiece_ops.py \
    --ignore=test_whisper.py \
    --ignore=test_pp_api.py \
    -k "not test_custom_pythonop_pytorch"; then
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
