#!/bin/bash -e
# -----------------------------------------------------------------------------
#
# Package       : matplotlib
# Version       : v3.11.0
# Source repo   : https://github.com/matplotlib/matplotlib.git
# Tested on     : UBI 9.6
# Language      : Python, C++, Jupyter Notebook
# Ci-Check  : True
# Script License: Apache License, Version 2 or later
# Maintainer    : Ryder Salinas <rbsalinas@ibm.com>
#
# Disclaimer: This script has been tested in root mode on given
# ==========  platform using the mentioned version of the package.
#             It may not work as expected with newer versions of the
#             package and/or distribution. In such case, please
#             contact "Maintainer" of this script.
#
# ----------------------------------------------------------------------------

PACKAGE_DIR="matplotlib"
PACKAGE_NAME="matplotlib"
PACKAGE_VERSION=${1:-v3.11.0}
PACKAGE_URL="https://github.com/matplotlib/matplotlib.git"
CURRENT_DIR="$(pwd)"
SCRIPT_PATH="$(dirname $(realpath $0))"

echo "Building ${PACKAGE_NAME} ${PACKAGE_VERSION}"

# -- System dependencies ------------------------------------------------------
dnf install -y \
    gcc-toolset-13 \
    git \
    python3.12 \
    python3.12-devel \
    python3.12-pip \
    libjpeg-turbo-devel \
    zlib-devel \
    libpng-devel \
    freetype-devel \
    lcms2-devel \
    libtiff-devel \
    libwebp-devel \
    openjpeg2-devel

export PATH="/opt/rh/gcc-toolset-13/root/usr/bin:$PATH"
gcc --version

# Compiler hints — help Pillow's setup.py locate system image headers
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib64"

python3.12 -m pip install --upgrade pip wheel build setuptools

# Clone and checkout
rm -rf "$PACKAGE_DIR"
git clone "$PACKAGE_URL"
cd "$PACKAGE_DIR"
git checkout "$PACKAGE_VERSION"
git submodule update --init --depth 1

# -- Build wheel --------------------------------------------------------------
python3.12 -m build --wheel --outdir "${CURRENT_DIR}/dist/"

WHEEL=$(find "${CURRENT_DIR}/dist" -name "${PACKAGE_NAME}-*.whl" | head -1)
if [ -z "$WHEEL" ]; then
    echo "ERROR: wheel not found after build"
    exit 1
fi
echo "Wheel: $WHEEL"

# -- Install ------------------------------------------------------------------
python3.12 -m pip install "$WHEEL"

# -- Tests --------------------------------------------------------------------
python3.12 - << 'PYEOF'
import sys

# 1. Import and version check
import matplotlib
assert matplotlib.__version__ == "3.11.0", f"Unexpected version: {matplotlib.__version__}"
print(f"PASS  import matplotlib {matplotlib.__version__}")

# 2. C extension sanity check
import matplotlib._c_internal_utils
print("PASS  C extension loaded")

# 3. Headless render — no display required
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import io

fig, ax = plt.subplots()
ax.plot(np.linspace(0, 2 * np.pi, 100), np.sin(np.linspace(0, 2 * np.pi, 100)))
ax.set_title("smoke test")
buf = io.BytesIO()
fig.savefig(buf, format="png")
plt.close(fig)
assert buf.tell() > 0
print("PASS  headless PNG render")

# 4. Key sub-packages importable
import matplotlib.pyplot
import matplotlib.patches
import matplotlib.colors
import matplotlib.ticker
import matplotlib.dates
print("PASS  key sub-packages importable")

print("\nAll tests passed.")
sys.exit(0)
PYEOF

echo "Build and tests complete. Wheel: $WHEEL"