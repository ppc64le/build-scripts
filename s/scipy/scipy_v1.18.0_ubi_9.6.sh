#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : scipy
# Version       : 1.18.0
# Source repo   : https://github.com/scipy/scipy
# Tested on     : UBI:9.6
# Language      : Python, C, C++, Fortran
# Ci-Check      : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Jason Cho <jason.cho2@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------
#!/bin/bash -e
PACKAGE_NAME="scipy"
PACKAGE_URL="https://github.com/scipy/scipy.git"
PACKAGE_VERSION=${1:-v1.18.0}
SOURCE_ROOT="$(pwd)"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

dnf install -y \
    git \
    gcc-toolset-15 \
    gcc-toolset-15-gcc-gfortran \
    openblas-devel \
    python3.12 \
    python3.12-devel \
    python3.12-pip

export PATH="/opt/rh/gcc-toolset-15/root/usr/bin:$PATH"
gcc --version

git clone "${PACKAGE_URL}"
cd "${PACKAGE_NAME}"
git checkout "${PACKAGE_VERSION}"
git submodule update --init 

# -- Build wheel --------------------------------------------------------------
export CXXFLAGS="-ftemplate-depth=2000"

python3.12 -m pip wheel --no-cache-dir --only-binary :none scipy==$PACKAGE_VERSION -w "${SOURCE_ROOT}/dist/"

# -- Find wheel ---------------------------------------------------------------
WHEEL=$(find "${SOURCE_ROOT}/dist" -name "scipy-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

# -- Install ------------------------------------------------------------------
python3.12 -m pip install "$WHEEL"

# -- Tests --------------------------------------------------------------------
cd "${SOURCE_ROOT}"   # <-- leave the source tree before importing scipy

python3.12 - << 'PYEOF'
import sys

import scipy
assert scipy.__version__ == "1.18.0", f"Unexpected version: {scipy.__version__}"
print(f"PASS  import scipy {scipy.__version__}")

import scipy.linalg, scipy.fft, scipy.optimize, scipy.stats, scipy.signal, scipy.sparse
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
res = minimize(lambda x: (x[0] - 1)**2 + (x[1] - 2)**2, [0, 0])
assert res.success and np.allclose(res.x, [1, 2], atol=1e-4)
print("PASS  optimize.minimize")

print("\nAll tests passed.")
sys.exit(0)
PYEOF

echo "Build and tests complete. Wheel: $WHEEL"
