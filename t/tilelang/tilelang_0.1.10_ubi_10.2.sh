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
PACKAGE_VERSION=${1:-v0.1.10}
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
pip install --upgrade pip setuptools wheel build

# ---------------------------------------------------------------------------
# Build z3-solver from source (no ppc64le binary on PyPI; required by tilelang
# with constraint z3-solver>=4.13.0,<4.15.5).
# Version z3-4.15.4 satisfies that range.
# ---------------------------------------------------------------------------
Z3_VERSION="z3-4.15.4"
Z3_DIR="${CURRENT_DIR}/z3-src"
rm -rf "$Z3_DIR"
git clone https://github.com/Z3Prover/z3 "$Z3_DIR"
cd "$Z3_DIR"
git checkout "$Z3_VERSION"

# Patch src/api/python/setup.py to recognise the ppc64le wheel platform tag
python3.12 - <<'PYEOF'
from pathlib import Path
p = Path("src/api/python/setup.py")
src = p.read_text()
entry = "    ('linux', 'ppc64le'): 'manylinux2014_ppc64le',\n"
if entry in src:
    print("  z3 setup.py already patched — skipping")
elif "TAGS = {" in src:
    p.write_text(src.replace("TAGS = {", "TAGS = {\n" + entry, 1))
    print("  z3 setup.py patched OK")
else:
    raise SystemExit("Could not find TAGS dict in z3 setup.py")
PYEOF

# Build the Z3 native library and install it system-wide
python3.12 scripts/mk_make.py
cd build
make -j"$(nproc)"
make install

# Build and install the Python bindings so 'import z3' works immediately
cd "$Z3_DIR/src/api/python"
python3.12 setup.py install

# Also produce a wheel so the artefact is available if needed
python3.12 setup.py bdist_wheel

# Return to the main working directory
cd "$CURRENT_DIR"
# ---------------------------------------------------------------------------

# Install all Python runtime + build dependencies from the IBM ppc64le wheels
# index.  torch is a hard unconditional runtime dep (tilelang/__init__.py:135
# calls `import torch` on every `import tilelang`).
#
# --prefer-binary lets pip select the wheel that best matches the running
# platform (UBI 10 / glibc 2.39 / POWER10); this gives better runtime
# performance than a UBI 8-built wheel because GCC 15 and the newer glibc
# enable POWER10 MMA intrinsics and improved VSX auto-vectorisation paths.
#
# torch-c-dlpack-ext is intentionally OMITTED: its wheel bundles
# libtorch_cuda.so which does not exist on a ROCm-only system and would cause
# a dlopen failure at import time.  tilelang/__init__.py:109-130 explicitly
# disables the dlpack extension when ROCm is detected, so it is not needed.
# (See tilelang docs: "skip torch-c-dlpack-ext on ROCm")
IBM_WHEELS="https://wheels.developerfirst.ibm.com/ppc64le/linux/+simple/"
pip install --trusted-host wheels.developerfirst.ibm.com \
    --extra-index-url "${IBM_WHEELS}" --prefer-binary \
    numpy tqdm cython patchelf "scikit-build-core[pyproject]" cmake ninja \
    torch \
    "apache-tvm-ffi>=0.1.11,<0.1.13" \
    cloudpickle ml-dtypes psutil "typing-extensions>=4.10.0"

# Clone repository
cd $CURRENT_DIR
git clone --recursive $PACKAGE_URL $PACKAGE_DIR
cd $PACKAGE_DIR
git checkout "${PACKAGE_VERSION}"
git submodule sync --recursive
git submodule update --init --recursive

# ---------------------------------------------------------------------------
# Patch pyproject.toml: remove torch-c-dlpack-ext from runtime dependencies.
#
# torch-c-dlpack-ext has no ppc64le binary on PyPI so pip tries to build it
# from source and fails when installing this wheel.  tilelang's __init__.py
# already disables it automatically on ROCm at runtime (checks
# torch.version.hip), so it is never actually used on this platform.
# ---------------------------------------------------------------------------
sed -i '/"torch-c-dlpack-ext/d' pyproject.toml
echo "Patched pyproject.toml: removed torch-c-dlpack-ext dependency"

# Build TileLang wheel
# USE_ROCM/USE_CUDA must be exported as environment variables AND passed via
# CMAKE_ARGS. version_provider.py reads os.environ directly (not CMAKE_ARGS)
# to decide the wheel name suffix; without the exports it falls through to the
# cuda branch and labels the wheel +cuda instead of +rocm.
export USE_ROCM=ON
export USE_CUDA=OFF
export CMAKE_ARGS="-DUSE_ROCM=ON -DUSE_CUDA=OFF"
export NO_GIT_VERSION=1

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
if ! python3.12 - <<'PYEOF'
import sys

print(f"Python: {sys.version}")

# 1. Basic import
print("\n[1] Importing tilelang...")
import tilelang
print(f"    tilelang version : {tilelang.__version__}")

# 2. TVM FFI bridge
print("\n[2] Checking TVM FFI bridge...")
import tvm_ffi
print(f"    tvm_ffi available: OK")

# 3. Z3 solver
print("\n[3] Checking Z3 solver...")
import z3
x = z3.Int("x")
solver = z3.Solver()
solver.add(x > 2, x < 10)
assert solver.check() == z3.sat, "Z3 solver returned unexpected result"
print(f"    z3 version       : {z3.get_version_string()}  (solver: OK)")

# 4. Torch import
print("\n[4] Checking torch...")
import torch
print(f"    torch version    : {torch.__version__}")
is_rocm = getattr(torch.version, "hip", None) is not None
print(f"    ROCm build       : {is_rocm}")
print(f"    HIP version      : {torch.version.hip if is_rocm else 'N/A'}")

# 5. Layout primitives
print("\n[5] Checking layout primitives...")
from tilelang.layout import Fragment, Layout
print("    Layout import    : OK")

print("\n══════════════════════════════════════════")
print("  All checks passed — tilelang stack OK")
print("══════════════════════════════════════════")
PYEOF
then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
fi

# ---------------------------------------------------------------------------
# pytest — repo-based tests (no-GPU safe subset)
#
# Run from CURRENT_DIR (NOT from inside the cloned repo) so that
# Python's import system resolves `import tilelang` to the installed wheel
# in site-packages rather than the local tilelang/ source folder sitting
# next to testing/.  Without this, the source .py files load but the
# compiled .so extensions are missing → ImportError.
#
# --import-mode=importlib  further prevents sys.path from being polluted
#                          with the repo root by pytest's default importer.
#
# Tests chosen: pure Python logic + ROCm arch helpers.
# All tests that call get_kernel_source() are excluded — that API triggers
# device detection and raises ValueError when no GPU is present.
# ---------------------------------------------------------------------------
TILELANG_TESTS="$CURRENT_DIR/$PACKAGE_DIR/testing/python"

pip install pytest pytest-timeout

cd "$CURRENT_DIR"

if ! pytest \
    "$TILELANG_TESTS/target/test_tilelang_rocm_target.py" \
    "$TILELANG_TESTS/utils/test_compress_utils.py" \
    "$TILELANG_TESTS/layout/test_tilelang_layout_equal.py" \
    "$TILELANG_TESTS/layout/test_tilelang_layout_repeat.py" \
    --import-mode=importlib \
    -v --timeout=60 ; then
    echo "------------------$PACKAGE_NAME:Install_success_but_test_fails---------------------"
    echo "$PACKAGE_URL $PACKAGE_NAME"
    echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub | Fail |  Install_success_but_test_Fails"
    exit 2
fi

echo "------------------$PACKAGE_NAME:Install_&_test_both_success-------------------------"
echo "$PACKAGE_URL $PACKAGE_NAME"
echo "$PACKAGE_NAME  |  $PACKAGE_URL | $PACKAGE_VERSION | GitHub  | Pass |  Both_Install_and_Test_Success"
exit 0
