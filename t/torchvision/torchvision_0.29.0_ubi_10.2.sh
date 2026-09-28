#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : torchvision
# Version          : v0.29.0
# Source repo      : https://github.com/pytorch/vision
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
#
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=torchvision
PACKAGE_VERSION=${1:-v0.29.0}
PACKAGE_URL=https://github.com/pytorch/vision
PACKAGE_DIR=vision
CURRENT_DIR=$(pwd)

WHEEL_DIR="${CURRENT_DIR}/wheels"
mkdir -p "${WHEEL_DIR}"

IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
IBM_WHEELS_HOST="wheels.developerfirst.ibm.com"
TORCH_VERSION="2.13.0"

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    gcc-toolset-15-gcc-gfortran \
    make cmake ninja-build \
    openblas-devel \
    pkg-config \
    libjpeg-turbo-devel libpng-devel libwebp-devel \
    zlib-devel openssl-devel libffi-devel \
    which curl tar

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

echo "Using gcc: $(gcc --version | head -1)"
echo "Using python: $(python3.14 --version)"

# ---------------------------------------------------------------------------
# Python build tools
# ---------------------------------------------------------------------------
NUMPY_VERSION=2.5.0
python3.14 -m pip install --upgrade pip setuptools wheel build packaging
python3.14 -m pip install \
    "meson-python>=0.18.0" "Cython>=3.0.6" meson ninja patchelf \
    "numpy==${NUMPY_VERSION}" pillow requests pytest pytest-mock

cd "${CURRENT_DIR}"

# ---------------------------------------------------------------------------
# Install torch 2.13.0 from IBM DeveloperFirst index
# torchvision setup.py imports torch at build time — must be installed first.
# ---------------------------------------------------------------------------
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "torch==${TORCH_VERSION}"


# ---------------------------------------------------------------------------
# Clone torchvision and checkout the requested version
# ---------------------------------------------------------------------------
cd "${CURRENT_DIR}"
git clone "${PACKAGE_URL}" "${PACKAGE_DIR}"
cd "${PACKAGE_DIR}"

# Strip leading 'v' if present — git tag is 'v0.29.0'
_TAG="${PACKAGE_VERSION}"
if ! git rev-parse "${_TAG}" &>/dev/null; then
    _TAG="v${PACKAGE_VERSION#v}"
fi
if ! git rev-parse "${_TAG}" &>/dev/null; then
    echo "ERROR: No git tag found for version '${PACKAGE_VERSION}'"
    exit 1
fi
git checkout "${_TAG}"

# ---------------------------------------------------------------------------
# Apply patches for PyTorch 2.13.0 Stable ABI compatibility: https://github.com/pytorch/vision/pull/9610
# ---------------------------------------------------------------------------
python3.14 - <<'PYEOF'
from pathlib import Path

# 1. Add permute helper to StableABICompat.h
p_compat = Path("torchvision/csrc/ops/StableABICompat.h")
src_compat = p_compat.read_text()
shim = '''
// aten::permute(Tensor self, int[] dims) -> Tensor
inline Tensor permute(const Tensor& self, std::vector<int64_t> dims) {
  std::array<StableIValue, 2> stack{
      torch::stable::detail::from(self), torch::stable::detail::from(dims)};
  TORCH_ERROR_CODE_CHECK(torch_call_dispatcher(
      "aten::permute", "", stack.data(), TORCH_ABI_VERSION));
  return torch::stable::detail::to<Tensor>(stack[0]);
}
'''
if "inline Tensor permute" not in src_compat:
    src_compat = src_compat.replace(
        "} // namespace stable_helpers",
        f"{shim}\n}} // namespace stable_helpers",
        1,
    )
    p_compat.write_text(src_compat)
    print("Patched StableABICompat.h with permute helper")

# 2. Update deform_conv2d_kernel.cpp to use stable_helpers::permute
p_kernel = Path("torchvision/csrc/ops/cpu/deform_conv2d_kernel.cpp")
src_kernel = p_kernel.read_text()
if "torch::stable::permute" in src_kernel:
    src_kernel = src_kernel.replace(
        "torch::stable::permute",
        "vision::ops::stable_helpers::permute",
    )
    p_kernel.write_text(src_kernel)
    print("Patched deform_conv2d_kernel.cpp to use stable_helpers::permute")
PYEOF

# ---------------------------------------------------------------------------
# Build torchvision wheel (CPU-only: FORCE_CUDA=0, no NVJPEG)
# ---------------------------------------------------------------------------
export FORCE_CUDA=0
export TORCHVISION_USE_NVJPEG=0

if ! python3.14 -m pip wheel \
        --no-build-isolation \
        --no-deps \
        -w "${WHEEL_DIR}" \
        .; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

cp "${WHEEL_DIR}"/*.whl "${CURRENT_DIR}/" 2>/dev/null || true
rm -f "${CURRENT_DIR}"/numpy-*.whl
# ---------------------------------------------------------------------------
# Install wheel
# ---------------------------------------------------------------------------
WHL=$(find "${CURRENT_DIR}" -maxdepth 2 -name "torchvision-*.whl" | head -1)
echo "Installing torchvision wheel: ${WHL}"
python3.14 -m pip install --no-deps --force-reinstall "${WHL}"

cd "${CURRENT_DIR}"

# ---------------------------------------------------------------------------
# Run package's own test suite via pytest
# Note: Tests parameterized with [cuda] are skipped automatically due to
#       CUDA device not available in CPU-only environments.
# ---------------------------------------------------------------------------
cd "${CURRENT_DIR}/${PACKAGE_DIR}"

if ! pytest test/test_architecture_ops.py \
           test/test_models_detection_anchor_utils.py \
           test/test_models_detection_negative_samples.py \
           test/test_internal_utils.py \
           test/smoke_test.py \
           test/test_ops.py -k "test_boxes_shape or test_is_leaf_node" -v; then
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
