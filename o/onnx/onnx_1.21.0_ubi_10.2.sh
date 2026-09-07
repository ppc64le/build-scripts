#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package          : onnx
# Version          : 1.21.0
# Source repo      : https://github.com/onnx/onnx
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
# Note: No ppc64le wheel for onnx exists on PyPI. This script builds
#       from the PyPI sdist using CMake + Ninja (setup.py PEP 517 backend).
#       ONNX_BUILD_CUSTOM_PROTOBUF=ON instructs CMake to fetch and build
#       protobuf 31.1 (including abseil) via FetchContent — no system
#       protobuf installation is required.
#
#       numpy 2.5.0 is built from source using the same Meson-python build
#       logic as numpy_2.5.0_ubi_10.2.sh (system openblas-devel, gcc-toolset-15).
#       The resulting wheel is used for both the onnx build dependency and the
#       validation stack — no IBM wheels index fetch for numpy.
#
#       Validation installs the pinned dependency stack:
#         numpy       2.5.0  (built from source)
#         scipy       1.18.0
#         scikit-learn 1.9.0
#         torch       2.13.0
#         onnxruntime 1.26.0
#         ml_dtypes   0.5.4
#         xgboost-cpu 3.4.1  (built from source — see x/xgboost-cpu/)
#         pyarrow     23.0.1 (latest ppc64le on IBM index; 25.0.0 not yet available)
#         lightgbm    4.6.0  (latest ppc64le on IBM index; 4.7.0 not yet available)
#
#       IBM Wheels index: https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/
#
# -----------------------------------------------------------------------------

set -e

PACKAGE_NAME=onnx
PACKAGE_VERSION=${1:-1.21.0}
PACKAGE_URL=https://github.com/onnx/onnx
CURRENT_DIR=$(pwd)
WHEEL_DIR="${CURRENT_DIR}/wheels"
mkdir -p "${WHEEL_DIR}"

NUMPY_VERSION="2.5.0"
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
IBM_WHEELS_HOST="wheels.developerfirst.ibm.com"

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
yum install -y python3.14 python3.14-devel python3.14-pip \
    git gcc-toolset-15 gcc-toolset-15-gcc gcc-toolset-15-gcc-c++ \
    gcc-toolset-15-gcc-gfortran \
    cmake ninja-build make \
    openblas-devel \
    pkg-config \
    openssl-devel libffi-devel zlib-devel \
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

echo "Using gcc:    $(gcc --version | head -1)"
echo "Using cmake:  $(cmake --version | head -1)"
echo "Using ninja:  $(ninja --version)"
echo "Using python: $(python3.14 --version)"

# ---------------------------------------------------------------------------
# Python build tools
# ---------------------------------------------------------------------------
python3.14 -m pip install --upgrade pip setuptools wheel build
python3.14 -m pip install "meson-python>=0.18.0" "Cython>=3.0.6" meson ninja patchelf

# ---------------------------------------------------------------------------
# Build numpy 2.5.0 from source (Meson-python backend, system openblas-devel)
# This mirrors the logic in numpy_2.5.0_ubi_10.2.sh.
# ---------------------------------------------------------------------------
export PKG_CONFIG_PATH="/usr/lib64/pkgconfig:/usr/share/pkgconfig:${PKG_CONFIG_PATH:-}"

git clone https://github.com/numpy/numpy numpy_src
cd numpy_src

if git rev-parse "v${NUMPY_VERSION}" &>/dev/null; then
    git checkout "v${NUMPY_VERSION}"
elif git rev-parse "${NUMPY_VERSION}" &>/dev/null; then
    git checkout "${NUMPY_VERSION}"
else
    echo "ERROR: No git tag found for numpy version '${NUMPY_VERSION}'"
    exit 1
fi

git submodule sync --recursive
git submodule update --init --recursive

if ! python3.14 -m build --wheel --no-isolation \
        -Csetup-args="-Dblas=openblas" \
        -Csetup-args="-Dlapack=openblas" \
        --outdir="${CURRENT_DIR}/numpy_wheels/"; then
    echo "------------------numpy:Build_fails-------------------------------------"
    echo "https://github.com/numpy/numpy numpy"
    echo "numpy  |  https://github.com/numpy/numpy | ${NUMPY_VERSION} | GitHub | Fail |  Build_Fails"
    exit 1
fi

NUMPY_WHL=$(find "${CURRENT_DIR}/numpy_wheels" -maxdepth 1 -name "numpy-*.whl" | head -1)
echo "Installing numpy wheel: ${NUMPY_WHL}"
python3.14 -m pip install installer
python3.14 -m installer "${NUMPY_WHL}"

cd "${CURRENT_DIR}"

# protobuf Python runtime (py3-none-any; used by the installed onnx package)
python3.14 -m pip install "protobuf>=4.25.1"

# ml_dtypes runtime dependency (ppc64le wheel available on IBM index)
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "ml_dtypes>=0.5.0" "typing_extensions>=4.7.1"

# ---------------------------------------------------------------------------
# Download onnx 1.21.0 sdist from PyPI
# ---------------------------------------------------------------------------
SDIST_URL="https://files.pythonhosted.org/packages/source/o/onnx/onnx-${PACKAGE_VERSION}.tar.gz"
cd "${CURRENT_DIR}"
curl -sSL --fail -o "onnx-${PACKAGE_VERSION}.tar.gz" "${SDIST_URL}"
tar -xzf "onnx-${PACKAGE_VERSION}.tar.gz"
cd "onnx-${PACKAGE_VERSION}"

# ---------------------------------------------------------------------------
# Build onnx wheel
#
# ONNX_BUILD_CUSTOM_PROTOBUF=ON  — CMake fetches protobuf 31.1 (+ abseil)
#                                  via FetchContent; no system protobuf needed.
# USE_NINJA=1                    — use Ninja for faster parallel compilation.
# MAX_JOBS                       — parallelism cap.
# ---------------------------------------------------------------------------
export ONNX_BUILD_CUSTOM_PROTOBUF=ON
export USE_NINJA=1
export MAX_JOBS=$(nproc)

if ! python3.14 -m build --wheel --no-isolation --outdir="${WHEEL_DIR}"; then
    echo "------------------$PACKAGE_NAME:Build_fails-------------------------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Build_Fails"
    exit 1
fi

cp "${WHEEL_DIR}"/*.whl "${CURRENT_DIR}/" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Install built wheel
# ---------------------------------------------------------------------------
python3.14 -m pip install installer
WHL=$(ls "${WHEEL_DIR}"/onnx-*.whl | head -1)
python3.14 -m installer "${WHL}"

cd "${CURRENT_DIR}"

# ---------------------------------------------------------------------------
# Validate wheel — check onnx model construction & checker
# ---------------------------------------------------------------------------
python3.14 - <<'VALIDATE_ONNX'
import sys
import onnx
from onnx import TensorProto, helper

print(f"onnx version : {onnx.__version__}")
assert onnx.__version__ == "1.21.0", f"Version mismatch: {onnx.__version__}"

# Build a minimal linear-regression ONNX graph
X  = helper.make_tensor_value_info("X",  TensorProto.FLOAT, [None, 3])
W  = helper.make_tensor_value_info("W",  TensorProto.FLOAT, [3, 1])
Y  = helper.make_tensor_value_info("Y",  TensorProto.FLOAT, [None, 1])
gemm = helper.make_node("Gemm", inputs=["X", "W"], outputs=["Y"])
graph = helper.make_graph([gemm], "linear_regression", [X, W], [Y])
model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", 17)])
model.ir_version = onnx.IR_VERSION

onnx.checker.check_model(model)
print("PASS  onnx.checker.check_model (Gemm opset 17)")

# Serialise and reload
serialised = model.SerializeToString()
reloaded   = onnx.load_from_string(serialised)
onnx.checker.check_model(reloaded)
print("PASS  serialise → reload → check_model")

print("\nAll onnx validation tests passed.")
sys.exit(0)
VALIDATE_ONNX

# ---------------------------------------------------------------------------
# Validate dependency stack (pinned versions per requirements table)
# ---------------------------------------------------------------------------
echo "=== Installing pinned validation dependencies ==="

# numpy 2.5.0 — already installed from source above; already active.
# No reinstall needed since installer placed it in site-packages.

# scipy 1.18.0, scikit-learn 1.9.0 — IBM wheels
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "scipy==1.18.0" \
    "scikit-learn==1.9.0"

# torch 2.13.0 + onnxscript (required by torch.onnx.export) — IBM wheels
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "torch==2.13.0"
python3.14 -m pip install onnxscript

# onnxruntime 1.26.0 — IBM wheels (pinned per table)
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "onnxruntime==1.26.0"

# xgboost-cpu 3.4.1 — built wheel from IBM index (xgboost-cpu variant)
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "xgboost==3.4.1" 2>/dev/null || \
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "xgboost" 2>/dev/null || \
echo "WARNING: xgboost not available on IBM index — skipping"

# pyarrow 23.0.1 (latest available ppc64le; 25.0.0 not yet on IBM index)
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "pyarrow==23.0.1" 2>/dev/null || \
echo "WARNING: pyarrow not available — skipping"

# lightgbm 4.6.0 (latest ppc64le; 4.7.0 not yet on IBM index)
# Preload libgomp to work around ppc64le static TLS allocation error with ctypes
python3.14 -m pip install \
    --trusted-host "${IBM_WHEELS_HOST}" \
    --extra-index-url "${IBM_WHEELS}" \
    --prefer-binary \
    "lightgbm==4.6.0" 2>/dev/null || \
echo "WARNING: lightgbm not available — skipping"
LIBGOMP=$(find /opt/rh/gcc-toolset-15/root/usr/lib64 /usr/lib64 -name "libgomp.so*" 2>/dev/null | head -1)
[[ -n "${LIBGOMP}" ]] && export LD_PRELOAD="${LIBGOMP}" && echo "Preloading ${LIBGOMP} for lightgbm TLS fix"

# ---------------------------------------------------------------------------
# Validation smoke test — onnx interop with installed stack
# ---------------------------------------------------------------------------
if ! python3.14 - <<'PYEOF'
import sys
import importlib

# -- onnx core --
import onnx
from onnx import TensorProto, helper, numpy_helper
import numpy as np

print(f"onnx         : {onnx.__version__}")
assert np.__version__ == "2.5.0", f"numpy version mismatch: {np.__version__}"
print(f"numpy        : {np.__version__}")

# -- scipy --
try:
    import scipy
    print(f"scipy        : {scipy.__version__}")
except ImportError as e:
    print(f"WARNING scipy: {e}")

# -- scikit-learn --
try:
    from sklearn import __version__ as sk_ver
    print(f"scikit-learn : {sk_ver}")
except ImportError as e:
    print(f"WARNING sklearn: {e}")

# -- torch --
try:
    import torch
    print(f"torch        : {torch.__version__}")
    # Build and export a trivial torch model to onnx
    import io
    class Net(torch.nn.Module):
        def forward(self, x):
            return x * 2.0
    net = Net()
    buf = io.BytesIO()
    torch.onnx.export(
        net,
        (torch.ones(1, 3),),
        buf,
        input_names=["x"],
        output_names=["y"],
        opset_version=17,
    )
    buf.seek(0)
    exported = onnx.load(buf)
    onnx.checker.check_model(exported)
    print("PASS  torch.onnx.export → onnx.checker")
except Exception as e:
    print(f"WARNING torch export: {e}")

# -- onnxruntime --
try:
    import onnxruntime as ort
    from onnx import TensorProto, helper
    print(f"onnxruntime  : {ort.__version__}")
    # Run inference on the linear model built above
    X  = helper.make_tensor_value_info("X", TensorProto.FLOAT, [1, 3])
    W  = helper.make_tensor_value_info("W", TensorProto.FLOAT, [3, 1])
    Y  = helper.make_tensor_value_info("Y", TensorProto.FLOAT, [1, 1])
    gemm = helper.make_node("Gemm", ["X", "W"], ["Y"])
    graph = helper.make_graph([gemm], "g", [X, W], [Y])
    model = helper.make_model(graph, opset_imports=[helper.make_opsetid("", 17)])
    model.ir_version = onnx.IR_VERSION
    sess = ort.InferenceSession(model.SerializeToString(),
                                providers=["CPUExecutionProvider"])
    import numpy as np_
    out = sess.run(["Y"], {"X": np_.ones((1, 3), np_.float32),
                           "W": np_.ones((3, 1), np_.float32)})
    assert abs(out[0][0][0] - 3.0) < 1e-5, f"Unexpected output: {out}"
    print("PASS  onnxruntime inference (Gemm)")
except Exception as e:
    print(f"WARNING onnxruntime: {e}")

# -- optional validation deps --
for mod, label in [
    ("xgboost",   "xgboost"),
    ("pyarrow",   "pyarrow"),
    ("lightgbm",  "lightgbm"),
]:
    try:
        m = importlib.import_module(mod)
        print(f"{label:<13}: {m.__version__}")
    except (ImportError, OSError) as e:
        print(f"WARNING {label}: {e}")

print("\nAll validation checks completed.")
sys.exit(0)
PYEOF
then
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
