#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scipy
# Version       : 1.18.0
# Source repo   : https://github.com/scipy/scipy
# Tested on     : UBI:10.2
# Language      : Python, C, C++, Fortran
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Sakshi Jain <sakshi.jain16@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# -----------------------------------------------------------------------------

PACKAGE_NAME="scipy"
PACKAGE_URL="https://github.com/scipy/scipy.git"
PACKAGE_VERSION=${1:-v1.18.0}
OPENBLAS_VERSION="v0.3.33"
OPENBLAS_URL="https://github.com/OpenMathLib/OpenBLAS"

SOURCE_ROOT="$(pwd)"
OPENBLAS_PREFIX="/install-deps/openblas"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# -----------------------------------------------------------------------------
# Install dependencies
# -----------------------------------------------------------------------------

dnf install -y \
    git \
    gcc-toolset-15 \
    gcc-toolset-15-gcc \
    gcc-toolset-15-gcc-c++ \
    gcc-toolset-15-gcc-gfortran \
    python3.14 \
    python3.14-devel \
    python3.14-pip \
    make \
    cmake \
    pkgconfig

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"

gcc --version
gfortran --version

# -----------------------------------------------------------------------------
# Install Python build dependencies
# -----------------------------------------------------------------------------

python3.14 -m pip install --upgrade pip setuptools wheel

python3.14 -m pip install \
    meson \
    meson-python \
    ninja \
    Cython \
    pybind11 \
    pythran \
    numpy==2.5.0

# -----------------------------------------------------------------------------
# Build OpenBLAS 0.3.33
# -----------------------------------------------------------------------------

echo "------------------ Building OpenBLAS ${OPENBLAS_VERSION} ------------------"

mkdir -p /install-deps

cd "${SOURCE_ROOT}"

git clone "${OPENBLAS_URL}"
cd OpenBLAS

git checkout "${OPENBLAS_VERSION}"
git submodule update --init

export USE_OPENMP=1
export USE_THREAD=1
export NUM_THREADS=8
export TARGET=POWER9
export DYNAMIC_ARCH=1
export INTERFACE64=0
export BUILD_BFLOAT16=1
export NO_AFFINITY=1

make -j$(nproc) \
    TARGET="${TARGET}" \
    BUILD_BFLOAT16="${BUILD_BFLOAT16}" \
    BINARY=64 \
    USE_OPENMP="${USE_OPENMP}" \
    USE_THREAD="${USE_THREAD}" \
    NUM_THREADS="${NUM_THREADS}" \
    DYNAMIC_ARCH="${DYNAMIC_ARCH}" \
    INTERFACE64="${INTERFACE64}" \
    NO_AFFINITY="${NO_AFFINITY}"

make install PREFIX="${OPENBLAS_PREFIX}"

export LD_LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${OPENBLAS_PREFIX}/lib64:${LD_LIBRARY_PATH:-}"
export PKG_CONFIG_PATH="${OPENBLAS_PREFIX}/lib/pkgconfig:${OPENBLAS_PREFIX}/lib64/pkgconfig:${PKG_CONFIG_PATH:-}"
export LIBRARY_PATH="${OPENBLAS_PREFIX}/lib:${OPENBLAS_PREFIX}/lib64:${LIBRARY_PATH:-}"
export CPATH="${OPENBLAS_PREFIX}/include:${CPATH:-}"

echo "------------------ OpenBLAS version ------------------"

pkg-config --modversion openblas || true

# -----------------------------------------------------------------------------
# Build SciPy
# -----------------------------------------------------------------------------

cd "${SOURCE_ROOT}"

git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"

git checkout "${PACKAGE_VERSION}"
git submodule update --init

# -- Build wheel --------------------------------------------------------------

export CXXFLAGS="-ftemplate-depth=2000"

mkdir -p "${SOURCE_ROOT}/dist"

python3.14 -m pip wheel \
    --no-cache-dir \
    --no-build-isolation \
    --no-deps \
    . \
    -w "${SOURCE_ROOT}/dist/"

# -- Find wheel ---------------------------------------------------------------

WHEEL=$(find "${SOURCE_ROOT}/dist" -name "scipy-*.whl" | head -1)

if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi

echo "Wheel: $WHEEL"

# -- Install ------------------------------------------------------------------

python3.14 -m pip install "$WHEEL"

# -- Tests --------------------------------------------------------------------

cd "${SOURCE_ROOT}"

python3.14 - << 'PYEOF'
import sys

import scipy

assert scipy.__version__ == "1.18.0", f"Unexpected version: {scipy.__version__}"
print(f"PASS  import scipy {scipy.__version__}")

import scipy.linalg
import scipy.fft
import scipy.optimize
import scipy.stats
import scipy.signal
import scipy.sparse

print("PASS  core submodules importable")

import numpy as np
from scipy.linalg import solve

A = np.array([[3, 1], [1, 2]], dtype=float)
b = np.array([9, 8], dtype=float)

x = solve(A, b)

assert np.allclose(x, [2.0, 3.0]), f"Unexpected result: {x}"
print("PASS  linalg.solve (BLAS/LAPACK)")

from scipy.fft import fft

sig = np.sin(2 * np.pi * np.linspace(0, 1, 256))

assert fft(sig).shape == (256,)

print("PASS  fft")

from scipy.optimize import minimize

res = minimize(
    lambda x: (x[0] - 1)**2 + (x[1] - 2)**2,
    [0, 0]
)

assert res.success and np.allclose(
    res.x,
    [1, 2],
    atol=1e-4
)

print("PASS  optimize.minimize")

print("\nAll tests passed.")

sys.exit(0)
PYEOF

echo "Build and tests complete. Wheel: $WHEEL"